package Image::TestJPG;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::TestJPG ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '1.0';

bootstrap Image::TestJPG $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::TestJPG - Test the validity of JPEG image streams.


=head1 SYNOPSIS

 use Image::TestJPG;

  # read data from a file
 open(JPEG, "<$file") or die "Can't open $file : $!\n";
 binmode JPEG;
 my $jpgData = do { local $/; <JPEG> };
 close(JPEG);
	
  # test the data
 $rv = Image::TestJPG::testJPG($jpgData, length($jpgData));

  # do something based on the return value
 if($rv) {
  ... jpeg data is valid ...
 }
 else {
  ... jpeg data contains errors ...
 }


=head1 DESCRIPTION

 This module provides a single function, testJPG, that will
 quickly decompress a JPEG stream.  If any errors are detected 
 during the decompression process the function returns 0, otherwise 
 it returns 1.

 Image::TestJPG::testJPG(<DATA>, <LENGTH OF DATA>);

 Typical uses of this module would include testing the validity
 of an uploaded jpg image, before storage.

=head1 EXPORT

 None by default.

=head1 AUTHOR

 Jason Hudgins <jasonlee@spy.net>

=head1 COPYRIGHT

 Copyright (c) 2007 Jason Hudgins.  All rights reserved.
 This program is free software; you can redistribute it
 and/or modify it under the same terms as Perl itself.

=cut
