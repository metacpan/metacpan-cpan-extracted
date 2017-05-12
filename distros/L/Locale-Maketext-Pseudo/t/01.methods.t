use Test::More tests => 7;

use lib '../lib', 't';

BEGIN {
use_ok( 'Locale::Maketext::Pseudo' );
}

diag( "Testing Locale::Maketext::Pseudo $Locale::Maketext::Pseudo::VERSION methods" );

my $fake = Locale::Maketext::Pseudo->new();
ok( ref $fake eq 'Locale::Maketext::Pseudo', 'new() object');

ok(
    $fake->maketext('Hello [_1], I am [_2]', 'World', 'Dan')  eq 'Hello World, I am Dan', 
    'maketext() interpolation in order'
);

ok(
    $fake->maketext('[_2]: Hello [_1], I am [_2]', 'World', 'Dan')  eq 'Dan: Hello World, I am Dan', 
    'maketext() interpolation in order - multi'
);

ok(
    $fake->maketext('Hello [_2], I am [_1]', 'World', 'Dan')  eq 'Hello Dan, I am World', 
    'maketext() interpolation out of order'
);

ok(
    $fake->maketext('[_1]: Hello [_2], I am [_1]', 'World', 'Dan')  eq 'World: Hello Dan, I am World', 
    'maketext() interpolation out of order - multi'
);

ok(
	$fake->maketext('[_-1]: Hello [_-2], I am [_1]', 'World', 'Dan') eq 'Dan: Hello World, I am World',
    'negative indexes'	
);