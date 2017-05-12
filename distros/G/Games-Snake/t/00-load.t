use strict;
use warnings;
use Test::More;

BEGIN {
    my @modules = qw(
        Games::Snake
        Games::Snake::Level
        Games::Snake::Player
    );

    for my $module (@modules) {
        use_ok($module) or BAIL_OUT("Failed to load $module");
    }
}

diag(
    sprintf(
        'Testing Games::Snake %f, Perl %f, %s',
        $Games::Snake::VERSION, $], $^X
    )
);

done_testing();

