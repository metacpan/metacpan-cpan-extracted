#!/usr/bin/perl -w -s
use strict;
use vars qw($a %u %g %time $VERSION);
use Filesys::Ext2 qw(lsattr calcSymMask);
$VERSION = 0.20;

{ #use Stat::lsMode qw(format_mode);
  #
  #
  # Stat::lsMode
  #
  # Copyright 1998 M-J. Dominus 
  # (mjd-perl-lsmode@plover.com)
  #
  # You may distribute this module under the same terms as Perl itself.
  #
  # $Revision: 1.2 $ $Date: 1998/04/20 01:27:25 $
  
  my @perms = qw(--- --x -w- -wx r-- r-x rw- rwx);
  my @ftype = qw(. p c ? d ? b ? - ? l ? s ? ? ?);
  $ftype[0] = '';
  
  sub format_mode {
    my $mode = shift;
    my %opts = @_;
    
    my $setids = ($mode & 07000)>>9;
    my @permstrs = @perms[($mode&0700)>>6, ($mode&0070)>>3, $mode&0007];
    my $ftype = $ftype[($mode & 0170000)>>12];
    
    if ($setids) {
      if ($setids & 01) {		# Sticky bit
	$permstrs[2] =~ s/([-x])$/$1 eq 'x' ? 't' : 'T'/e;
      }
      if ($setids & 04) {		# Setuid bit
	$permstrs[0] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
      }
      if ($setids & 02) {		# Setgid bit
	$permstrs[1] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
      }
    }   
    join '', $ftype, @permstrs;
  }
}

push(@ARGV, '.') unless @ARGV;


my @mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

{ #Files
  my @lines;
  for (grep {-l || ! -d} @ARGV) {
    push @lines, (do_file($_))[1];
  }
  print map {$_->[1]} sort {$a->[0] cmp $b->[0]} @lines;
}

  #Directories
foreach my $d (grep {-d && ! -l} @ARGV) {
  my($blocks, @lines);
  if( opendir(DIR, $d) ){
    my @files = readdir(DIR);

    # -a
    unless( $a ){
      @files = grep {!/^\./} @files;
    }
    
    print "\n", $d, ":\n" unless @ARGV == 1;
    ($blocks, @lines) = do_files($d, @files);
    closedir DIR;
  }
  else{
    warn "ls: $d: $!\n";
  }
  print "total $blocks\n";
  print map {$_->[1]} sort {$a->[0] cmp $b->[0]} @lines;
}


sub do_files {
  my @lines;
  my $dir = shift;
  my $tot_blocks = 0;

  #Pre-lsattr
  my @attr = lsattr( map {"$dir/$_"} @_);

  for(my $i=0; $i < scalar @_; $i++ ){
    my ($blocks, $line) = do_file($dir, $_[$i], $attr[$i]);
    $tot_blocks += $blocks;
    push @lines, $line;
  }
  ($tot_blocks/2, @lines);
}

sub do_file {
  my($dir, $file, $attr) = @_;
  my ($dev,undef,$mode,$nlink,$uid,$gid,undef,$size,
      undef,$mtime,undef,undef,$blocks) = lstat "$dir/$file";

  unless (defined $dev) {
    warn "ls: $_: $!\n";
    return;
  }
  
  my $name = -l _ ? "$file -> ". readlink "$dir/$file" : $file;
  
  #-h the size
  my $unit=0;
  my @unit=('', 'K', 'M', 'G', 'T');
  while( $size>1023 && $unit[$unit+1] ){
    $size/=1024;
    $unit++
  }
  $size = substr($size, 0, 3);
  chop($size) if index($size, '.') == length($size)-1;
  $size = $size . $unit[$unit];

  #compress the attr
  $attr = defined($attr) ? calcSymMask($attr) : '~~~~~~~~';
  $attr =~ y/-//d;

  ( $blocks,
    [$name, 
     sprintf("%s %3d %-8s %-8s % 4s %s %8s %s\n", 
	     format_mode($mode),
	     $nlink, 
	     ui($uid, $gid),
	     $size, 
	     format_time($mtime),
	     $attr,
	     $name,
	    )
    ]
  );
}

sub ui {
  ($u{$_[0]} ||= getpwuid($_[0]) || $_[0]),
    ($g{$_[1]} ||= getgrgid($_[1]) || $_[1]);
}

sub format_time {
  return $time{$_[0]} if exists $time{$_[0]};
  my $timestr;
  my($sec, $min, $hour, $day, $mon, $year) = localtime($_[0]);

  if( $_[0] < $^T - 180*24*3600 || $_[0] > $^T + 3600 ){
    $timestr = sprintf "$mon[$mon] %2d  %4d", $day, $year+1900;
  }
  else{
    $timestr = sprintf "$mon[$mon] %2d %02d:%02d", $day, $hour, $min;
  }

  $time{$_[0]} = $timestr;
}

__END__

=pod

=head1 NAME

ls2.pl - list directory contents with their ext2 and ext3 attributes

=head1 SYNOPSIS

B<ls2.pl> [B<-a>] [F<FILEs>]

=head1 DESCRIPTION

List information about the F<FILEs> (the current directory by default).
Output is in the format of B<ls> -lh merged with the attributes from
B<lsattr> in the second to the last column.

=over

=item -a

Do not hide entries starting with I<.>

=back

=head1 SEE ALSO

L<ls(1)>, L<lsattr(1)>, L<Filesys::Ext2>

=head1 AUTHORS

Jerrad Pierce <jpierce@cpan.org>.

Based upon ls by Mark-Jason Dominus <mjd-perl-lsmode@plover.com>.
Includes portions of Stat::lsStat by
Mark-Jason Dominus <mjd-perl-lsmode@plover.com>.

Human readable size (B<-h>) by James Mastros.

=head1 LICENSE

You may distribute this module under the same terms as Perl itself.

=cut
