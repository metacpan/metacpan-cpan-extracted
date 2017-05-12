use Test::More tests => 38;

use Game::RockPaperScissorsLizardSpock;

diag("Testing Game::RockPaperScissorsLizardSpock $Game::RockPaperScissorsLizardSpock::VERSION");

ok( defined &rpsls, 'rpsls() exported' );

is( rpsls( 'scissors', 'paper' ),    1, 'scissors cut paper' );
is( rpsls( 'paper',    'rock' ),     1, 'paper covers rock' );
is( rpsls( 'rock',     'lizard' ),   1, 'rock crushes lizard' );
is( rpsls( 'lizard',   'Spock' ),    1, 'lizard poisons Spock' );
is( rpsls( 'Spock',    'scissors' ), 1, 'Spock smashes scissors' );
is( rpsls( 'scissors', 'lizard' ),   1, 'scissors decapitates lizard' );
is( rpsls( 'lizard',   'paper' ),    1, 'lizard eats paper' );
is( rpsls( 'paper',    'Spock' ),    1, 'paper disproves Spock' );
is( rpsls( 'Spock',    'rock' ),     1, 'Spock vaporizes rock' );
is( rpsls( 'rock',     'scissors' ), 1, 'and as it always has … rock crushes scissors' );

is( rpsls( 'paper',    'scissors' ), 2, 'scissors cut paper' );
is( rpsls( 'rock',     'paper' ),    2, 'paper covers rock' );
is( rpsls( 'lizard',   'rock' ),     2, 'rock crushes lizard' );
is( rpsls( 'Spock',    'lizard' ),   2, 'lizard poisons Spock' );
is( rpsls( 'scissors', 'Spock' ),    2, 'Spock smashes scissors' );
is( rpsls( 'lizard',   'scissors' ), 2, 'scissors decapitates lizard' );
is( rpsls( 'paper',    'lizard' ),   2, 'lizard eats paper' );
is( rpsls( 'Spock',    'paper' ),    2, 'paper disproves Spock' );
is( rpsls( 'rock',     'Spock' ),    2, 'Spock vaporizes rock' );
is( rpsls( 'scissors', 'rock' ),     2, 'and as it always has … rock crushes scissors' );

is( rpsls( 'rock',     'rock' ),     3, 'rock tie' );
is( rpsls( 'paper',    'paper' ),    3, 'paper tie' );
is( rpsls( 'scissors', 'scissors' ), 3, 'scissors tie' );
is( rpsls( 'lizard',   'lizard' ),   3, 'lizard tie' );
is( rpsls( 'Spock',    'Spock' ),    3, 'Spock tie' );

ok( rpsls('rock'),     'rock 1 player' );
ok( rpsls('paper'),    'paper 1 player' );
ok( rpsls('scissors'), 'scissors 1 player' );
ok( rpsls('lizard'),   'lizard 1 player' );
ok( rpsls('Spock'),    'Spock 1 player' );

is_deeply( [ rpsls() ], [], 'no arg return' );
is_deeply( [ rpsls( undef,   'rock' ) ], [], 'player one undef return' );
is_deeply( [ rpsls( '',      'rock' ) ], [], 'player one empty string return' );
is_deeply( [ rpsls( 'blorp', 'rock' ) ], [], 'player one bad choice return' );
ok( rpsls( 'rock', undef ), 'player two undef makes choice for you' );
is_deeply( [ rpsls( 'rock', '' ) ],      [], 'player two empty string return' );
is_deeply( [ rpsls( 'rock', 'blorp' ) ], [], 'player two bad choice return' );
