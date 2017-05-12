package Image::Filter;

require Exporter;
require DynaLoader;
use vars qw(@ISA $VERSION);
@ISA = qw(Exporter DynaLoader);
$VERSION = 0.07;
bootstrap Image::Filter $VERSION;

sub filter
{ my $self = shift;
  my $filter = shift;
  my @params = @_;
  my $module = ucfirst lc $filter;
  eval qq{ use Image::Filter::$module; };
  no strict 'refs';
  return &{$filter}($self,@params);
}

1;
__END__
=head1 NAME

Image::Filter - Apply filters onto images.

=head1 SYNOPSIS

    use Image::Filter;

    $image = Image::Filter::newFromJpeg("munich.jpg");
    $image = $image->filter("blur");
    $image->Jpeg("blurtest.jpg",$quality); #1-100, use negative value for default
    $image->Destroy;

=head1 DESCRIPTION

Image::Filter is a perl module that can apply image filters. A limited number
of filters are included (see list below). Image::Filter currently does true 
color images images. It uses the gd2 lib from Thomas Boutell.

=head1 EXPORT

None by default.

=head1 FILTERS

=over 4

=item Blur

Basic, none to fancy, blur routine (truecolor)

=item Channel

Extract Red, Green or Blue channels from an image (truecolor)

=item Edge

Basic, none to fancy, Black and White edge routine

=item Emboss

Basic, none to fancy, Black and White emboss routine

=item Eraseline

Erase every Nth line, with a specific color, thickness, either horizontally or vertically (truecolor)

=item Floyd

Dither an image using basic a Floyd-Steinberg Dither algorithm.

=item Foo

Basic, none to fancy, foo routine. Example filter

Oh yeah, this is a dummy filter :)

=item Gaussian

Gaussian Blur (truecolor)

=item Greyscale

Basic, weighted average greyscale routine

=item Invert

Basic, none to fancy, invert routine (truecolor)

=item Level

Basic, none to fancy, level routine. Add a certain value to every RGB value (truecolor)

=item Oilify

Oilify algorithm. Quite processor intensive. (truecolor

=item Pixelize

Basic, none to fancy, pixelize routine (truecolor)

=item Posterize

Basic, none to fancy, Black and White posterize routine (truecolor)

=item Ripple

Add ripples (truecolor)

=item Rotate

Basic, none to fancy, Counter Clockwise Rotation routine (truecolor)

=item Sharpen

Basic, none to fancy, sharpen routine (truecolor)

=item Solarize

Solarize an image (truecolor)

=item Swirl

Funny rotation routine (truecolor)

=item Twirl

Funny rotation routine (truecolor)

=back

=head1 METHODS

=over 4

=item newFromJpeg($filename)

Load data from a JPEG file. Returns an Image::Filter instance

=item newFromPng($filename)

Load data from a PNG file. Returns an Image::Filter instance

=item newFromGd($filename)

Load data from a gd file. Returns an Image::Filter instance

=item newFromGd2($filename)

Load data from a gd2 file. Returns an Image::Filter instance

=item filter($image,$filter)

Apply a filter to an Image::Filter instance. Image preferably passed as Instance variable

$image->filter($filter);

=item Jpeg($filename,$quality)

Dump image data to JPEG file. Existing file will be overwritten (if possible). Quality is optional. Possible values range from 0 to 100 (Higher value is higher quality). Use negative value for default quality.

=item Png($filename)

Dump image data to PNG file. Existing file will be overwritten (if possible).

=item Gd($filename)

Dump image data to gd file. Existing file will be overwritten (if possible).

=item Gd2($filename)

Dump image data to gd2 file. Existing file will be overwritten (if possible).

=item Destroy

Destroy the instance of Image::Filter. (RECOMMENDED USE)

=back

=head1 CALL FOR PARTICIPATION

Obviously, I'm no expert in math or C. If you feel like writing some filter code or have a nice algorithm you want to see implemented, give me a shout.

=head1 AUTHOR

Hendrik Van Belleghem, E<lt>beatnik + at + quickndirty + dot + orgE<gt>

=head1 LICENSE

Image::Filter is released under the GNU Public License. See COPYING and 
COPYRIGHT for more information.

=head1 THANKS & CREDITS

Image::Filter is based on the concepts tought to me by my math professor
J. Van Hee. This module wouldn't be possible without the work of Thomas 
Boutell on his gd library. Inspiration, but no code, was taken from Lincoln
D. Steins GD implementation of that same gd lib. 

=head1 SEE ALSO

L<perl>.

=cut
