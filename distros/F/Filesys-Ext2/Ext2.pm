package Filesys::Ext2;
require 5;
use strict;
use vars q($VERSION);
use IO::Handle;
use IO::Select;
use IPC::Open3;
$VERSION = 0.20;
local($_);

#XXX You may want to change this default if you installed
#XXX e2fsprogs in a non-standard location
local $ENV{PATH} = '/usr/bin/';

my %attr = (
	    s => 0x00000001, u => 0x00000002, c => 0x00000004, S => 0x00000008,
	    i => 0x00000010, a => 0x00000020, d => 0x00000040, A => 0x00000080,
	    Z => 0x00000100,                  X => 0x00000400, E => 0x00000800,
	    I => 0x00001000,                  j => 0x00004000, t => 0x00008000,
	    D => 0x00010000, T => 0x00020000,
	   );

sub import{
  no strict 'refs';
  my $caller = caller(1);
  shift;
  
  @_ = map { $_ eq ':all' ? qw(chattr lsattr stat lstat calcSymMask) : $_ } @_;
  foreach( @_ ){
    if(ref($_) eq 'HASH'){
      if(exists($_->{PATH})){
	$ENV{PATH} = $_->{PATH};
      }
    }
    else{
      *{$caller."::$_"} = \&{'Filesys::Ext2::'.$_};
    }
  }
}

sub chattr($$;@){
  my($mask, @files) = @_;
  my @mask = $mask =~ /^\d+/ ?
    '=' . join('', grep { y/+// } _calcSymMask($mask)) :
      split(/\s+|(?=[+-=])/, $mask);

  my($R, $E) = _multi("chattr", @mask, @files);

  die($E) if $?;
  return 0;
}

sub lsattr(@){
  my $dir = '-d' if grep { -d } @_;

  my %attr;

  #Skip things that we know lsattr will croak on
  $attr{$_} = undef for grep{ -l || ! (-d || -f || -r) }  @_;  
  my($R, $E) = _multi("lsattr", $dir, grep { (-d || -f || -r) && ! -l } @_);

  die($E) if($?);

  foreach( split(/\n\r?|\r/, $R) ){
    my($val, $key) = split(/\s+/, $_, 2);
    $attr{$key} = (_calcBitMask($val)||"0 but true");
  }

  my @mask = @attr{@_};

  return wantarray ? @mask : $mask[0];
}

sub stat($) {
  my $lsattr = eval { lsattr($_[0]) };
  my $stat = CORE::stat($_[0]);
  if( $@ ){
    return wantarray ? () : 0;
  }
  else{
    return wantarray ? (CORE::stat(_), $lsattr) : $stat && ($@ ? 0 : 1);
  }
}
	 
sub lstat($) {
  my $lsattr = eval { lsattr($_[0]) };
  my $stat = CORE::lstat($_[0]);
  if( $@ ){
    return wantarray ? () : 0;
  }
  else{
    return wantarray ? (CORE::stat(_), $lsattr) : $stat && ($@ ? 0 : 1);
  }
}
	  
sub calcSymMask($) {
  my @F = _calcSymMask($_[0]);
  return @F if wantarray;
  
  $_ = join('', @F);
  y/+//d;
  s/(?<=-)[sucSiadAZXEIjtDT]//g;
  return $_;
}

sub _multi{
  my($WFH, $RFH, $EFH, $ERR, $OUT);

  #XXX splice to limited no. of files at a time?
  my $pid = open3(
		  $WFH = new IO::Handle,
		  $RFH = new IO::Handle,
		  $EFH = new IO::Handle,
		  @_
		 );

  $_->autoflush() for $RFH, $EFH;

  my $selector = IO::Select->new();
  $selector->add($RFH, $EFH);
  while( my @ready = $selector->can_read ){
    foreach my $fh ( @ready ){
      if( fileno($fh) == fileno($RFH) ){
	my $ret = $RFH->sysread($_, 1024);
	$OUT .= $_;
	$selector->remove($fh) unless $ret;
      }
      if( fileno($fh) == fileno($EFH) ){
	my $ret = $EFH->sysread($_, 1024);
	$ERR .= $_;
	$selector->remove($fh) unless $ret;
      }
    }
  }
  
  waitpid $pid, 0;
  
  return $OUT, $ERR;
}

sub _calcBitMask($) {
  my $bitmask;
  while ( my($key, $val) = each(%attr) ){
    $bitmask += (index($_[0], $key)>=0) * $val;
  }
  return $bitmask;
}

sub _calcSymMask($) {
  my @mask;
  foreach ( sort { $attr{$a} <=> $attr{$b} } keys %attr ){
    push @mask, ($_[0] & $attr{$_} ? "+$_" : "-$_");
  }
  return @mask;
}

1;
__END__
=pod

=head1 NAME

Filesys::Ext2 - Interface to ext2 and ext3 filesystem attributes

=head1 SYNOPSIS

  use Filesys::Ext2 qw(:all);
  eval { $mode = lsattr("/etc/passwd"); }
  eval { chattr("+aud", "/etc/passwd"); }
  #or equivalently
  #chattr($mode|0x0062, "/etc/passwd");

=head1 DESCRIPTION

You may specify the path of the e2fsprogs upon use

  use Filesys::Ext2 {PATH=>'/path/to/binaries'};

Otherwise the module will use the default path /usr/bin/

=over 8

=item chattr(I<$mask>, @files)

Change the mode of F<@files> to match I<$mask>.
I<$mask> may be a bitmask or symbolic mode eg;

  =DIE
  +cad
  -s-i

Throws an exception upon failure.

=item lsattr(F<@files>)

Returns bitmasks respresenting the attributes of F<@files>.

Throws an exception upon failure.

=item lstat(F<$file>)

Same as C<CORE::lstat>, but appends the numerical attribute bitmask.

=item stat(F<$file>)

Same as C<CORE::stat>,  but appends the numerical attribute bitmask.

=item calcSymMask(I<$mask>)

Accepts a bitmask and returns the symbolic mode.
In list context it returns a symbol list like lsattr,
in scalar context it returns a string that matches the
I<-> region of B<lsattr(1)> eg;

  s-----A------

=back

=head1 SEE ALSO

L<chattr(1)>, L<lsattr(1)>

=head1 NOTES

Ideally this would be implemented with XS, maybe someday.

The bit mappings for attributes, from other/ext2_fs.h

=over

=item 0x00000001 == s

Secure deletion

=item 0x00000002 == u

Undelete

=item 0x00000004 == c

Compress file

=item 0x00000008 == S

Synchronous updates

=item 0x00000010 == i

Immutable file

=item 0x00000020 == a

Writes to file may only append

=item 0x00000040 == d

Do not dump file

=item 0x00000080 == A

Do not update atime

=item 0x00000100 == Z

Dirty compressed data

Not user modifiable.

=item 0x00000400 == X

Access raw compressed data

Not (currently) user modifiable.

=item 0x00000800 == E

Compression error.

Not user modifiable.

=item 0x00001000 == I

btree format dir / hash-indexed directory

Not user modifiable.

=item 0x00004000 == j

File data should be journaed

=item 0x00008000 == t

File tail should not be merged

=item 0x00010000 == D

Synchronous directory modifications

=item 0x00020000 == T

Top of directory hierarchies

=back

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

=cut
