use strict;
use warnings;
use Test::More;

BEGIN {
    my @modules = qw(
        Games::SolarConflict
        Games::SolarConflict::ComputerPlayer
        Games::SolarConflict::Controller::GameOver
        Games::SolarConflict::Controller::MainGame
        Games::SolarConflict::Controller::MainMenu
        Games::SolarConflict::HumanPlayer
        Games::SolarConflict::Roles::Controller
        Games::SolarConflict::Roles::Drawable
        Games::SolarConflict::Roles::Explosive
        Games::SolarConflict::Roles::Physical
        Games::SolarConflict::Roles::Player
        Games::SolarConflict::Spaceship
        Games::SolarConflict::Sprite::Rotatable
        Games::SolarConflict::Sun
        Games::SolarConflict::Torpedo
    );

    for my $module (@modules) {
        use_ok($module) or BAIL_OUT("Failed to load $module");
    }
}

diag(
    sprintf(
        'Testing Games::SolarConflict %f, Perl %f, %s',
        $Games::SolarConflict::VERSION,
        $], $^X
    )
);

done_testing();

