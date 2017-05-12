package Image::PNGwriter;

use 5.008005;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::PNGwriter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	PNGWRITER_DEFAULT_COMPRESSION
	PNGWRITER_H
	PNGWRITER_VERSION
	PNG_BYTES_TO_CHECK
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	PNGWRITER_DEFAULT_COMPRESSION
	PNGWRITER_H
	PNGWRITER_VERSION
	PNG_BYTES_TO_CHECK
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Image::PNGwriter::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Image::PNGwriter', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Image::PNGwriter - Use pngwriter from Perl.

=head1 SYNOPSIS

  # General syntax:
  use Image::PNGwriter;
  my $pngwriter = Image::PNGwriter->new(640,480,1,'a.png');
  # ... do stuff with it ...
  $pngwriter->write_png();

  # Another use:
  my $pngwriter = Image::PNGwriter->new(640,480,1,'a.png');
  $pngwriter->resize(1000,1100);
  $pngwriter->clear();
  $pngwriter->filledsquare(1,1,1000,1100,1,1,1);
  for(300..500) { $pngwriter->circle(500,500,$_,0,$_/1000,0); }
  for(0..100) { $pngwriter->plot($_,1,0,0.4,0); }
  for(0..100) { $pngwriter->plotHSV($_,10,0,0.4,0); }
  $pngwriter->filledcircle(500,500,100,1,0,0);
  $pngwriter->plot_text('/path/to/arial.ttf',50,300,300,0,'from perl!',1,0.4,0.4);
  $pngwriter->plot_text_utf8('/path/to/kochi-mincho.ttf',20,500,500,0,$utf_text,1,1,0);
  print 'Height: '.$pngwriter->getheight()."\n";
  print 'Width: '.$pngwriter->getwidth()."\n";
  print 'Bit depth: '.$pngwriter->getbitdepth()."\n";
  print 'Colortype: '.$pngwriter->getcolortype()."\n";
  print 'Gamma: '.$pngwriter->getgamma()."\n";
  print 'Pixel at (100,100) RGB: ';
  print $pngwriter->dread(100,100,1).' '.
    $pngwriter->dread(100,100,2).' '.
	$pngwriter->dread(100,100,3)."\n";
  print 'Pixel at (100,100) HSV: ';
  print $pngwriter->dreadHSV(100,100,1).' '.
	$pngwriter->dreadHSV(100,100,2).' '.
	$pngwriter->dreadHSV(100,100,3)."\n";
  print 'PNGWriter library version: '.$pngwriter->version()."\n";
  print 'Interpolated pixel at (100.3,100,3) RGB: ';
  print $pngwriter->bilinear_interpolation_dread(100.3,100.3,1).' ';
  print $pngwriter->bilinear_interpolation_dread(100.3,100.3,2).' ';
  print $pngwriter->bilinear_interpolation_dread(100.3,100.3,3)."\n";
  $pngwriter->write_png();


=head1 DESCRIPTION

This is a first version of a pngwriter module for perl. It supports most
of the features of pngwriter itself except for polygons. This will be
fixed in a later release.

=head2 EXPORT

None by default.

=head1 SEE ALSO

pngwriter.

=head1 NOTICE

This module is work in progress - the documentation will be updated as
the module matures.

=head1 AUTHOR

Andres Kievsky, E<lt>ank@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Andres Kievsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
