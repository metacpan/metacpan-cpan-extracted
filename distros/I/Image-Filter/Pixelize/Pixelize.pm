# This file was automatically generated by SWIG
package Image::Filter::Pixelize;
require Exporter;
require DynaLoader;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(pixelize);
$VERSION = 0.07;
package Image::Filter::Pixelize;
bootstrap Image::Filter::Pixelize;

1;
__END__
=head1 NAME

Image::Filter::Pixelize - Pixelize an image.

=head1 SYNOPSIS

    use Image::Filter;

    $image = Image::Filter::newFromJpeg("munich.jpg");
    $image = $image->filter("pixelize"); #Load Image::Filter::Pixelize
    $image->Jpeg("test.jpg"); 

=head1 DESCRIPTION

Image::Filter is a perl module that can apply image filters. This module
implements a simple pixelize routine. It uses the gd lib from Thomas Boutell.
This filter handles true color images.

=head1 EXPORT

pixelize

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
