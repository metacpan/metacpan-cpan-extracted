use strict;
use warnings;

use blib;
use Benchmark;

use Image::TextMode;
use Image::TextMode::Format::ANSI;
use Image::TextMode::Reader::ANSI;
use Image::TextMode::Reader::ANSI::XS;

my $file  = shift;
my $iters = 50;

die "No file specified" unless $file;
die "File '${file}' does not exist" unless -e $file;

printf "Image\::TextMode version %s\n", Image::TextMode->VERSION;
printf "Image\::TextMode\::Reader\::ANSI\::XS version %s\n",
    Image::TextMode::Reader::ANSI::XS->VERSION;
printf "Filesize: %d bytes\n", -s ( $file );

my $image_pp = Image::TextMode::Format::ANSI->new;
my $image_xs = Image::TextMode::Format::ANSI->new;

open( my $f, '<', $file );
binmode( $f );

my $r = Benchmark::timethese(
    $iters,
    {   'PP' => sub { local $ENV{ IMAGE_TEXTMODE_NOXS } = 1; $image_pp->read( $f, { width => 80 } ) },
        'XS' => sub { $image_xs->read( $f, { width => 80 } ) },
    }
);

close( $f );

Benchmark::cmpthese( $r );

