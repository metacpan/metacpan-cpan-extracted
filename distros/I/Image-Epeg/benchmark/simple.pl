use strict;
use warnings;
use Image::Epeg qw(:constants);
use Benchmark ':all';
use GD;
use Imager;
use Image::Magick;

print "# Image::Epeg   $Image::Epeg::VERSION\n";
print "# Imager        $Imager::VERSION\n";
print "# GD            $GD::VERSION\n";
print "# Image::Magick $Image::Magick::VERSION\n";

my $srcfile = shift or die "Usage: $0 fname";
my $src = Image::Epeg->new($srcfile);
print "# origsize: @{[ $src->get_width ]} x @{[ $src->height ]}\n";
my $width = int($src->get_width * 0.4);
my $height = int($src->get_height * 0.4);
print "# size: $width x $height\n";

timethese(
    1 => {
        epeg => sub {
            my $epeg = Image::Epeg->new( $srcfile );
            $epeg->resize( $width, $height, MAINTAIN_ASPECT_RATIO );
            $epeg->write_file( "epeg.jpg" );
        },
        (
            map { 
                my $qtype = $_;
                "Imager-$_" => sub {
                    my $img = Imager->new;
                    $img->read(file => $srcfile) or die;
                    my $scaled = $img->scale(xpixels => $width, ypixels => $height, qtype => $qtype) or die;
                    $scaled->write(file => "imager-$qtype.jpg", type => 'jpeg') or die;
                }
            }
            qw/ normal mixing preview /
        ),
        (
            map {
                my $method = $_;
                "GD-$_" => sub {
                    my $gd = GD::Image->new($srcfile) or die;
                    my $scaled = GD::Image->new( $width, $height );
                    $scaled->$method( $gd, 0, 0, 0, 0, $width, $height,
                        $gd->width, $gd->height );

                    open my $fh, '>', "gd-$method.jpg";
                    print $fh $scaled->jpeg;
                    close $fh;
                };
            }
            qw/copyResized copyResampled/
        ),
        imagemagick => sub {
            my $img = Image::Magick->new;
            $img->Read($srcfile);
            $img->Resize(
                width  => $width,
                height => $height,
            );
            $img->Write('imagemagick.jpg');
        },
        "imagemagick-lanczos" => sub {
            my $img = Image::Magick->new;
            $img->Read($srcfile);
            $img->Resize(
                width  => $width,
                height => $height,
                filter => 'Lanczos',
            );
            $img->Write('imagemagick-lanczos.jpg');
        }
    }
);
