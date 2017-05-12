#!perl -T

use Test::More tests => 11;

BEGIN {

    $Games::Tournament::Swiss::Config::algorithm =
      'Games::Tournament::Swiss::Procedure::Dummy';
    $Games::Tournament::Swiss::Config::firstround = 1;

    # @Games::Tournament::Swiss::Config::roles=qw/One Another/;
    # %Games::Tournament::Swiss::Config::scores=
    #	(win => 2, loss => 3, draw => 4, absent => 5);
    use_ok('Games::Tournament::Contestant');
    use_ok('Games::Tournament::Contestant::Swiss');
    use_ok('Games::Tournament::Contestant::Swiss::Preference');
    use_ok('Games::Tournament');
    use_ok('Games::Tournament::Swiss::Config');
    use_ok('Games::Tournament::Card');
    use_ok('Games::Tournament::Swiss::Procedure::FIDE');
    use_ok('Games::Tournament::Swiss::Procedure');
    use_ok('Games::Tournament::Swiss::Procedure::Dummy');
    use_ok('Games::Tournament::Swiss::Bracket');
    use_ok('Games::Tournament::Swiss');
}

diag(
"Testing Games::Tournament::Swiss $Games::Tournament::Swiss::VERSION, Perl $], $^X"
);
