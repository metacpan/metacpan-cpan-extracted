use Test::More tests => 5;

use_ok( 'HTTP::SimpleLinkChecker' );

ok( defined &HTTP::SimpleLinkChecker::user_agent );

my $UA = &HTTP::SimpleLinkChecker::user_agent();
isa_ok( $UA, 'Mojo::UserAgent');

like( $UA->transactor->name, qr/Mojolicious/ );

my $new_name = "brian's link checker";
$UA->transactor->name( $new_name );
is( $UA->transactor->name, $new_name );
