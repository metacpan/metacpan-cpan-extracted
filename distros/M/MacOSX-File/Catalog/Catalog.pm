package MacOSX::File::Catalog;

=head1 NAME

MacOSX::File::Catalog - Get (HFS) Catalog Information for that file

=head1 SYNOPSIS

  use MacOSX::File::Catalog;
  $catalog = MacOSX::File::Catalog->get($path);
  $catalog->type('TEXT');
  $catalog->creator('ttxt');
  $catalog->flags(-invisible => 1);
  $catalog->set;

=head1 DESCRIPTION

This module allows you to get all gettable attributes of the file or
directory specified and set all settable attributes thereof.  This
module is a superset of MacOSX::File::Info.  You can also think this
module as stat() for HFS.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $RCSID = q$Id: Catalog.pm,v 0.70 2005/08/09 15:47:00 dankogai Exp $;
our $VERSION = do { my @r = (q$Revision: 0.70 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MacOSX::File::Catalog ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

=head2 EXPORT

Subs: getcatalog(), setcatalog()

=cut

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		 getcatalog
		 setcatalog
		 );

bootstrap MacOSX::File::Catalog $VERSION;
use MacOSX::File;

# Preloaded methods go here.

=head1 METHODS

=over 4

=item $catalog = MacOSX::File::Catalog->get($path);

=item $catalog = getfileinfo($path);

Constructs MacOSX::File::Catalog from which you can manipulate file
attributes.  On failure, it returns undef and $MacOSX::File::OSErr
is set. 

=cut

use MacOSX::File::Constants;

sub getcatalog{
    my ($path) = @_;
    my $self = xs_getcatalog($path) or return;
    @$self or return;
    bless $self;
}

sub get{
    my ($class, $path) = @_;
    my $self = xs_getcatalog($path) or return;
    @$self or return;
    bless $self => $class;
}

=item $catalog->set([$path]);

=item setcatalog($catalog, [$path]);

Sets file attributes of file $path.  If $path is omitted the file you
used to construct $catalog is used.  On success, it returns 1.  On
failure, it returns 0 and $MacOSX::File::OSErr is set.

Remember any changes to $catalog will not be commited until you call
these functions.

  ex)
    setcatalog(getcatalog("foo"), "bar"); 
    #Copies file attributes from foo to bar

=cut

sub setcatalog{
    my ($catalog, $path) = @_;
    ref $catalog eq __PACKAGE__ or return;
    return !xs_setcatalog($catalog, $path);
}

sub set{
    my ($self, $path) = @_;
    ref $self eq __PACKAGE__ or return;
    return !xs_setcatalog($self, $path);
}

=item $catalog->dump

returns a pretty-printed string that contains the value of every
(gettable) member of FSCatalogInfo structure.

    ex) print $catalog->dump;

=back

=cut

sub dump{
    use POSIX qw(strftime);
    my $s = shift;
    my $t2s = sub { 
	strftime("%Y.%m.%d %H:%M:%S", localtime($_[0]))
	    . "." . ($_[0]-int($_[0]));
	};
    my $octlist = sub { join ",", map {sprintf "0%o" ,$_} @_ };
    return 
	join("\n",
	     "(FSRef)",
	     sprintf("nodeFlags =>                  0x%04x", $s->[1]),
	     sprintf("volume =>                     %6d", $s->[2]),
	     sprintf("parentDirID =>            0x%08x", $s->[3]),
	     sprintf("nodeID =>                 0x%08x", $s->[4]),
	     sprintf("sharingFlags =>                 0x%02x", $s->[5]),
	     sprintf("userPrivileges =>               0x%02x", $s->[6]),
	     sprintf("createDate =>             %s", $t2s->($s->[7])),
	     sprintf("contentModDate =>         %s", $t2s->($s->[8])),
	     sprintf("attributeModDate =>       %s", $t2s->($s->[9])),
	     sprintf("accessDate =>             %s", $t2s->($s->[10])),
	     sprintf("backupDate =>             %s", $t2s->($s->[11])),
	     sprintf("permissions =>            ["),
	     sprintf("                          %10d, # uid", $s->[12][0]),
	     sprintf("                          %10d, # gid", $s->[12][1]),
	     sprintf("                             0%6o, # mode", $s->[12][2]),
	     sprintf("                          0x%08x, # device", $s->[12][3]),
	     sprintf("                          ]"),
	     sprintf("finderInfo =>      "),
	     sprintf(" fdType =>                    '%s'",  $s->[13][0]),
	     sprintf(" fdCreator =>                 '%s'",  $s->[13][1]),
	     sprintf(" fdFlags =>                   0x%04x", $s->[13][2]),
	     sprintf(" fdLocation =>                [%s]", 
		     join(",", @{$s->[13][3]})),
	     sprintf(" fdFldr =>                    0x%04x", $s->[13][4]),
	     sprintf("extFinderInfo =>      "),
	     sprintf("  fdIconID =>                 0x%04x", $s->[14][0]),
	     sprintf("  fdScript =>                 0x%04x", $s->[14][1]),
	     sprintf("  fdXFlags =>                   0x%02x", $s->[14][2]),
	     sprintf("  fdComment =>                  0x%02x", $s->[14][3]),
	     sprintf("  fdPutAway =>            0x%08x", $s->[14][4]),
	     sprintf("dataLogicalSize =>  %16.0f", $s->[15]),
	     sprintf("dataPhysicalSize => %16.0f", $s->[16]),
	     sprintf("rsrcLogicalSize =>  %16.0f", $s->[17]),
	     sprintf("rsrcPhysicalSize => %16.0f", $s->[18]),
	     sprintf("valence =>                0x%08x", $s->[19]),
	     sprintf("textEncodingHint =>       0x%08x", $s->[20]),
	     "\n");
}

# Construct accessor methods all at once

my %_ro = 
    (
     ref              => 0,
     nodeFlags        => 1,
     volume           => 2,
     parentDirID      => 3,
     nodeID           => 4,
     sharingFlags     => 5,
     userPrivileges   => 6,
     dataLogicalSize  => 15,
     dataPhysicalSize => 16,
     rsrcLogicalSize  => 17,
     rsrcPysicalSize  => 18,
     valence          => 19,
     );

while(my($field, $index) = each %_ro){
    no strict 'refs';
    *$field = sub { $_[0]->[$index] };
}

my  %_rw_scalar =
    (
     createDate       => 7,
     contentModDate   => 8,
     attributeModDate => 9,
     accessDate       => 10,
     backupDate       => 11,
     textEncodingHint => 20, 
     );

while(my($field, $index) = each %_rw_scalar){
    no strict 'refs';
    *$field = sub { 
	my $self = shift;
	@_ or return $self->[$index];
	$self->[$index] = $_[0];
    };
}

my %_rw_aref = 
    (
     permissions      => 12,
     finderInfo       => 13,
     extFinderInfo    => 14,
     );

while(my($field, $index) = each %_rw_aref){
    no strict 'refs';
    *$field = sub { 
	my $self = shift;
	@_ or return $self->[$index];
        for(my $i = 0; $i < $#_; $i++){
	    $self->[$index][$i] = $_[$i];
	}
	return $self->[$index];
    };
}

=head2 file lock

The file lock status is stored in $catalog->nodeFlags but this field
is supposed to be read-only.  Use the following methods instead

  $catalog->locked
  $catalog->lock
  $catalog->unlock

=cut

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

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head2 Read-only access methods

The following methods returns the value of each field;

    $catalog->ref              Used Internally to store FSRef
    $catalog->nodeFlags        see lock() method
    $catalog->volume           vRefnum there of. Corresponds to st_dev
    $catalog->parentDirID      dirID thereof 
                               equiv. to lstat(dirname($path))->ino;
    $catalog->nodeID           nodeID thereof
                               equiv. to lstat($path)->ino;
    $catalog->sharingFlags    
    $catalog->userPrivileges
    $catalog->valence           

=head2 Access methods with scalar argument

The following methods returns the value of each field without
argument.  With argument, it sets the value within.

=over 4

=item $catalog->createDate

Content Creation Date.  equiv. to stat($path)->ctime

=item $catalog->contentModDate

Content Modification Date. equiv. to stat($path)->mtime

=item $catalog->attributeModDate  

Attribute Modification Date.  Unlike Unix, this value is stored as
file attribute.  On Unix, mtime of the containing directory would be
changed.

=item $catalog->accessDate

Content Access date. equiv. to stat($path)->atime

=item $catalog->backupDate

Backup date.  This field is hardly ever used.

=item $catalog->textEncodingHint

Text Encoding Hint

Note that dates in this module is stored as double while catalog
stores as UTCDateTime, which is a 64bit fixed floating point. 48bits
are for integral part and 16bits are for fractional part.  The
conversion is done automagically but it won't hurt you to know.

=back

=head2 Access methods with list argument

The following methods returns the value of each field as list context without
argument.  With argument, it sets the value within. when fewer
arguments are fed, only first arguments are set with the remaining
fields untouched.

eg) $catalog->finderInfo('TEXT', 'ttxt')
    # changes type and creator with flags and others unchanged

=over 4

=item ($uid, $gid, $mode, $specialDevice) = $catalog->permissions(...)

returns 4-element list whose values are UID, GID, MODE there of. 

SEE
http://developer.apple.com/technotes/tn/tn1150.html#HFSPlusPermissions
for the use of this field. 

=item ($type, $creator, $flags, $location, $fdfldr) = $catalog->finderInfo(...)

returns 5-element list whose values are type, creator, flags, location
and folder information.  Only first 3 would be relevant for you.  Note
this module contains no ->flags method, unlike MacOSX::File::Info
module.

=item ($iconID, $script, $xflags, $comment, $putaway) = $catalog->extFinderInfo(...)

returns 5-element list whose values are iconID, xflags, comment and
putaway values.  I confess I know nothing about this field;  I just
faithfully coded accordingly to Carbon document.  Leave it as it is
unless you know what you are doing.

=back

=head1 AUTHOR

Dan Kogai <dankogai@dan.co.jp>

=head1 SEE ALSO

L<MacPerl>

Inside Carbon: File Manager F<http://developer.apple.com/techpubs/macosx/Carbon/Files/FileManager/File_Manager/index.html>

=head1 COPYRIGHT

Copyright 2002 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
