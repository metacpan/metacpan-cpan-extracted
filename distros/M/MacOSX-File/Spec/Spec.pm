package MacOSX::File::Spec;

use 5.006;
use strict;
use warnings;
use Carp;

our $RCSID = q$Id: Spec.pm,v 0.70 2005/08/09 15:47:00 dankogai Exp $;
our $VERSION = do { my @r = (q$Revision: 0.70 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $DEBUG;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MacOSX::File::Spec ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		 path2spec
		 );

bootstrap MacOSX::File::Spec $VERSION;
use MacOSX::File;

sub path2spec { MacOSX::File::Spec->new(@_) }

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

MacOSX::File::Spec - Access FFSpec structure

=head1 SYNOPSIS

  use MacOSX::File::Spec;
  $spec = MacOSX::File::Spec->new($path);
  # or
  $spec = path2spec($path);
  # 
  vRefNum = $spec->vRefNum;
  parID   = $spec->parID;
  name    = $spec->name;
  ($vRefNum, $parID, $name) = $spec->as_array
  path    = $spec->path;

=head1 DESCRIPTION

This module allows you to access FSSpec structure, which is used to
locate files on MacOS.  Though MacOS X allows you to access any files
via path like any decent UNIX, you may still have to access files via
old-fasioned MacOS way so here is the module.

=over 4

=item $spec = MacOSX::File::Spec->new($path);
=item $spec = path2spec($path)

Creates MacOSX::File::Spec object from which you can access members
within.
When any error occurs, undef is returned and $MacOS::File::OSErr is
set to nonzero.

=item $spec->vRefNum

Returns Volume Reference Number.  Its Unix equivalent would be
stat($path)->dev. 

=item $spec->parID

Returns Parent ID, or the Directory ID of the directory in which the
file resides.  Its Unix equivalent would be stat(dirname($path))->ino
but as you know, Unix does not allow you to access directly via
i-node.

=item $spec->name

Returns file name without path component.

=item ($vRefNum, $parID, $name) = $spec->as_array

Returns vRefNum, parID, and name all at once.

=item $spec->path

Returns the absolute path which is reconstructed via FSSpec.  Not
necessarily equal to $path when you constructed this object.  Could be
handy when you want an absolute path of a file which path you know
only relatively.

=back

=head2 EXPORT

path2spec(), which is an alias of MacOSX::File::Spec->new();

=head1 AUTHOR

Dan Kogai <dankogai@dan.co.jp>

=head1 SEE ALSO

L<MacOSX::File>

 L<File::Spec>

Inside Carbon: File Manager F<http://developer.apple.com/techpubs/macosx/Carbon/Files/FileManager/filemanager.html>

=head1 COPYRIGHT

Copyright 2002 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
