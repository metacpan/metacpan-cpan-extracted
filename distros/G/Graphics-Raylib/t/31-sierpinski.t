use Test::More;
use strict;
use warnings;
use integer;

my $SIZE = 300;

use Graphics::Raylib '+family';

my $g = Graphics::Raylib->window($SIZE, $SIZE);
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};

my $bitmap = Graphics::Raylib::Shape->bitmap(
    matrix => [([(0)x$SIZE]) x $SIZE], # We don't care for the actual values, so it's ok they alias
    color => sub {
        my (undef, $x, $y) = @_;
        while( $x > 0 || $y > 0 ) {
            return BLACK if $x % 3 == 1 and $y % 3 == 1;

            $x /= 3;
            $y /= 3;
        }
        return
    });
$g->fps(1);

$g->clear;
Graphics::Raylib::draw {
    $bitmap->draw;
};

sleep($ENV{RAYLIB_TEST_SLEEP_SECS} // 1);
ok 1;
done_testing
