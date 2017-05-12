package MacOSX::File::Info;

=head1 NAME

MacOSX::File::Info - Gets/Sets (HFS) File Attributes

=head1 SYNOPSIS

  use MacOSX::File::Info;
  $finfo = MacOSX::File::Info->get($path);
  $finfo->type('TEXT');
  $finfo->creator('ttxt');
  $finfo->flags(-invisible => 1);
  $finfo->set;

=head1 DESCRIPTION

This module implements what /Developer/Tools/{GetFileInfo,SetFile}
does within perl.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $RCSID = q$Id: Info.pm,v 0.70 2005/08/09 15:47:00 dankogai Exp $;
our $VERSION = do { my @r = (q$Revision: 0.70 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $DEBUG;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MacOSX::File::Info ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

=head2 EXPORT

Subs: getfinfo(), setfinfo()

=cut

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		 getfinfo
		 setfinfo
		 );

bootstrap MacOSX::File::Info $VERSION;
use MacOSX::File;

# Preloaded methods go here.

sub DESTROY{
    $DEBUG or return;
    carp "Destroying ", __PACKAGE__;
    return;
}

=head1 METHODS

=over 4

=item $finfo = MacOSX::File::Info->get($path);

=item $finfo = getfileinfo($path);

Constructs MacOSX::File::Info from which you can manipulate file
attributes.  On failure, it returns undef and $MacOSX::File::OSErr
is set. 

=cut

sub getfinfo{
    my ($path) = @_;
    my $self = xs_getfinfo($path);
    defined $self or return;
    bless $self;
}

sub get{
    my ($class, $path) = @_;
    my $self = xs_getfinfo($path);
    defined $self or return;
    bless $self => $class;
}

=item $finfo->set([$path]);

=item setfinfo($finfo, [$path]);

Sets file attributes of file $path.  If $path is omitted the file you
used to construct $finfo is used.  On success, it returns 1.  On
failure, it returns 0 and $MacOSX::File::OSErr is set.

Remember any changes to $finfo will not be commited until you call
these functions.

  ex)
    setfinfo(getfinfo("foo"), "bar"); 
    #Copies file attributes from foo to bar

=cut

sub setfinfo{
    my ($info, $path) = @_;
    ref $info eq __PACKAGE__ or return;
    $path ||= ""; # to keep warnings quiet;
    return !xs_setfinfo(@$info, $path);
}

sub set{
    my ($self, $path) = @_;
    ref $self eq __PACKAGE__ or return;
    $path ||= ""; # to keep warnings quiet;
    return !xs_setfinfo(@$self, $path);
}

=item $clone  = $finfo->clone;

Returns a cloned (deep-copied) object.  Handy when you want to compare changes.

=cut

sub clone{
    my $self = shift;
    my (@new) = @$self;
    bless \@new, (ref $self);
}

=item $finfo->ref(), $finfo->nodeFlags(),

returns FSRef and nodeFlags of the file.  these attributes are read
only.  Use of these methods are unlikely except for debugging purpose.

=cut

# Construct accessor methods all at once

my %_ro = (
	   ref        => 0,
	   nodeFlags  => 1,
	   );

while(my($field, $index) = each %_ro){
    no strict 'refs';
    *$field = sub { $_[0]->[$index] };
}

=item $finfo->type([$type]), $finfo->creator([$creator])

Gets and sets file type and creator, respectively.  Though they accept
strings longer than 4 bytes, only the first 4 bytes are used.

=item $finfo->ctime($ctime), $finfo->mtime($mtime)

Gets and sets file creation time and content modification time,
respectively.

  ex)
    $finfo->mtime(time());

Time is specified by seconds passed since Unix Epoch, January 1, 1970
00:00:00 UTC.  Beware this is different from Native Macintosh Epoch,
January 1, 1904, 00:00:00 UTC.  I made it that way because perl on
MacOSX uses Unix notion of Epoch.  (FYI MacPerl uses Mac notion of
Epoch). 

These methods accept fractional numbers since Carbon supports it.  It
also accepts numbers larger than UINT_MAX for the same reason.

=item $finfo->fdflags($fdflags)

Gets and sets fdflags values.  However, the use of this method is
discouraged unless you are happy with bitwise operation.  Use
$finfo->flags method instead.

  ex)
    $finfo->fdflags($finfo->fdflags | kIsInvisible)
    # makes the file invisible

=cut

my %_rw = (
	   type              => 2,
	   creator           => 3,
	   fdFlags           => 4,
	   ctime             => 5,
	   mtime             => 6,
	   );


while(my($field, $index) = each %_rw){
    no strict 'refs';
    *$field = sub  {
	my $self = shift;
	@_ and $self->[$index] = shift;
	$self->[$index];
    };
}


=item $flags = $finfo->flags($attributes), %flags = $finfo->flags(%attributes)

Gets and sets fdflags like /Developer/Tools/SetFile.  You can use
SetFile-compatible letter notation or more intuitive args-by-hash
notation.


When you use Attribute letters and corresponding swithes as
follows. Uppercase to flag and lowercase to flag.

    Letter Hash key         Description
    -----------------------------------
    [Aa]   -alias           Alias file
    [Vv]   -invisible       Invisible*
    [Bb]   -bundle          Bundle
    [Ss]   -system          System (name locked)
    [Tt]   -stationery      Stationary
    [Cc]   -customicon      Custom icon*
    [Ll]   -locked          Locked
    [Ii]   -inited          Inited*
    [Nn]   -noinit          No INIT resources
    [Mm]   -shared          Shared (can run multiple times)
    [Ee]   -hiddenx         Hidden extension*
    [Dd]   -desktop         Desktop*

Attributes with asterisk can be applied to folders and files.  Any
other can be applied to files only.

  ex)
    $attr = $finfo->flags("avbstclinmed"); 
    # unflag eveythinng
    $attr = $finfo->flags("L");
    # locks file with the rest of attributes untouched
    $attr = $finfo->flags(-locked => 1);
    # same thing but more intuitive

On scalar context, it returns attrib. letters.  On list context, it
returns hash notation shown above;

=back

=cut

use MacOSX::File::Constants;

my %Key2Letter =
    qw(
       -alias      a
       -invisible  v
       -bundle     b
       -system     s
       -stationery t
       -customicon c
       -locked     l
       -inited     i
       -noinit     n
       -shared     m
       -hiddenx    e
       -desktop    d
       );
my %Letter2Key = reverse %Key2Letter;
my @Letters    = qw(a v b s t c l i n m e d);
my %key2Flags = 
    (
     -alias      =>  kIsAlias,
     -invisible  =>  kIsInvisible,
     -bundle     =>  kHasBundle,
     -system     =>  kNameLocked,
     -stationery =>  kIsStationery,
     -customicon =>  kHasCustomIcon,
     -locked     =>  kFSNodeLockedMask,
     -inited     =>  kHasBeenInited,
     -noinit     =>  kHasNoINITs,
     -shared     =>  kIsShared,
     -hiddenx    =>  kIsHiddenExtention,
     -desktop    =>  kIsOnDesk,
     );

sub locked{
    my $self = shift;
    return $self->nodeFlags & kFSNodeLockedMask;
}

sub lock{
    my $self = shift;
    $self->[1] = $self->nodeFlags | kFSNodeLockedMask;
    return $self;
}

sub unlock{
    my $self = shift;
    $self->[1] = $self->nodeFlags & ~kFSNodeLockedMask;
    return $self;
}

sub flags{
    my $self = shift;
    my ($fdFlags, $nodeFlags) = ($self->fdFlags, $self->nodeFlags);
    my %attrib = (
		  -alias      => $fdFlags & kIsAlias,
		  -invisible  => $fdFlags & kIsInvisible,
		  -bundle     => $fdFlags & kHasBundle,
		  -system     => $fdFlags & kNameLocked,
		  -stationery => $fdFlags & kIsStationery,
		  -customicon => $fdFlags & kHasCustomIcon,
		  -locked     => $nodeFlags & kFSNodeLockedMask,
		  -inited     => $fdFlags & kHasBeenInited,
		  -noinit     => $fdFlags & kHasNoINITs,
		  -shared     => $fdFlags & kIsShared,
		  -hiddenx    => $fdFlags & kIsHiddenExtention,
		  -desktop    => $fdFlags & kIsOnDesk,
		  );
    my $attrib = "";
    unless (@_){
	wantarray and return %attrib;
	for my $l (@Letters){
	    $attrib .=  $attrib{$Letter2Key{$l}} ? uc($l) : $l;
	}
	return $attrib;
    }
    if (scalar(@_) == 1){ # Letter notation
	my $letters = shift;
	for my $l (map { chr } unpack("C*", $letters)){
	    $attrib{$Letter2Key{lc($l)}} = ($l =~ tr/[A-Z]/[A-Z]/) ? 1 : 0;
	}
    }else{
	my %args = @_;
	for my $k (keys %args){
	    exists $attrib{$k} and $attrib{$k} = $args{$k};
	}
    }
    $fdFlags = 0;
    for my $k (keys %attrib){
	if ($k eq '-locked'){
	    $attrib{$k} ? $self->lock : $self->unlock;
	}else{
	    $fdFlags |= $attrib{$k} ? $key2Flags{$k} : 0;
	}
    }
    $self->fdFlags($fdFlags);

    defined wantarray or return;
    wantarray and return %attrib;
    for my $l (@Letters){
	$attrib .=  $attrib{$Letter2Key{$l}} ? uc($l) : $l;
    }
    return $attrib;
}
# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 AUTHOR

Dan Kogai <dankogai@dan.co.jp>

=head1 SEE ALSO

  L<MacPerl>
  F</Developer/Tools/GetFileInfo>
  F</Developer/Tools/SetFile>

=head1 COPYRIGHT

Copyright 2002 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
