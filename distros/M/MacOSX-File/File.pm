package MacOSX::File;

use 5.006;
use strict;
use Carp;

our $RCSID = q$Id: File.pm,v 0.71 2005/08/19 06:11:07 dankogai Exp $;
our $VERSION = do { my @r = (q$Revision: 0.71 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw( unlink strerr );
our @EXPORT_OK = qw( $OSErr $CopyErr );
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

our $OSErr;
our $CopyErr;

sub strerr{
    require MacOSX::File::Constants;
    return &MacOSX::File::Constants::ResultCode->{$OSErr};
}

sub unlink {
    my $count = 0;
    for my $f (@_){
	if (CORE::unlink $f){
	    $count++;
	    my $dotunderscore = $f; 
	    $dotunderscore =~ s{ ([^/]+)$ }{ '._' . $1}xeo;
	    unlink $dotunderscore;
	}
    }
    return $count;
}

1;

__END__

=head1 NAME

MacOSX::File - A collection of modules to manipulate files on MacOS X

=head1 TIGER

As of Mac OS X v10.4 (Tiger), most of these operations with
resource fork are supported by the ordinary (cp|mv|rsync).
If you are looking for psync, you may as well consider using
rsync -E instead.

=head1 DESCRIPTION

MacOSX::File is a collection of modules that allows you to do what
binaries in  /Developer/Tools allows you to do directly via perl.
You can implement your own CpMac, MvMac, GetFileInfo and SetFile
without calling these binaries.

=head1 Subroutines defined in MacOSX::File itself

Others are defined in other submodules.  see SUBMODULES below.

=head2 EXPORT

by default: unlink(), strerr()

on request: $OSErr, $CopyErr

=over 4

=item unlink(@files)

Just like CORE::unlink, deletes a list of files.  Returns the number
of files successfully deleted.  In addition to that,
MacOSX::File::unlink also attempts to delete '._' files, files used in
UFS volume to store Finder attributes and Resouce fork.

  $cnt = unlink 'a', 'b', 'c'; # deletes 'a', 'b', 'c'
                               # and     '._a', '._b', '._c'
                               # and returns 3 if all of them are
                               # unlinked

=item strerr()

Return string representation of File Manager errors if any.  See
MacOSX::File::Constants for details.

=back
              
=head1 SUBMODULES

  MacOSX::File::Catalog    - Gets/Sets FSCatalogInfo Attributes
  MacOSX::File::Copy       - copy/move with HFS(+) attributes
  MacOSX::File::Info       - Gets/Sets File Attributes (Subset of ::Catalog)
  MacOSX::File::Spec       - Gets FSSpec Structure

=head1 SCRIPTS

  pcpmac     - CpMac reimplemented
  pmvmac     - MvMac reimplemented
  pgetfinfo  - GetFileInfo reimplemented
  psetfinfo  - SetFile reimplemented
  psync      - update copy utility, very reason I wrote this module

=head1 INSTALLATION

To install this module, first make sure Developer kit is
installed.  Then type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires MacOS X.  Develper kit is needed to "make
install".

=head1 COPYRIGHT AND LICENCE

Copyright 2002-2003 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
