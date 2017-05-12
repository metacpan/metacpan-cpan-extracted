use Test::Most;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

plan skip_all => 'Skipping this until dynamic resizing added'
    unless $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

use v5.10.1;

use File::Temp qw/ tempdir /;
use Imager::Fill;
use Imager::Bing::MapLayer;

my $cleanup = $ENV{TMP_NO_CLEANUP} ? 0 : 1;

my $image = Imager::Bing::MapLayer->new(
    base_dir => tempdir( CLEANUP => $cleanup ),    #
    overwrite => 0,
    in_memory => 10,
    min_level => 19,
    max_level => 19,
);

# local $SIG{INT} = sub {
#     state $int = 0;
#     unless ($int) {
#         ++$int;
#         $image->save();
#     }
#     exit 1;
# };

my @bbox = ( 51.48426, -0.08009, 51.66931, 0.10084 );

lives_ok {

    $image->polygon(
        points => [
            [ $bbox[0], $bbox[1] ],
            [ $bbox[2], $bbox[1] ],
            [ $bbox[2], $bbox[3] ],
            [ $bbox[0], $bbox[3] ],
            [ $bbox[0], $bbox[1] ],
        ],
        fill => Imager::Fill->new(
            type    => 'opacity',
            opacity => 0.5,
            other   => Imager::Fill->new(
                solid   => Imager::Color->new( 255, 0, 0 ),
                combine => 'normal',
            ),
        ),
    );

}
'plot a very large polygon';

done_testing;
