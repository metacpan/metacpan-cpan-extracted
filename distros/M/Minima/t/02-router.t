use v5.40;
use Test2::V0;
use Path::Tiny;

use Minima::Router;

my $r = Minima::Router->new;
my $routes = Path::Tiny->tempfile;

# Works without doing nothing
is( $r->match('/'), undef, 'works out of the box' );

# Non-existing routes file
like(
    dies { $r->read_file('ThisFileDoesNotExist') },
    qr/does not exist/,
    'dies for non-existing routes file'
);

# Comments and blanks
$routes->spew(<<~EOF
    # Comment

    # GET / C A
    EOF
);
$r->read_file($routes);
is( $r->match('/'), undef, 'ignores comments and blank lines' );

# Specials
is( $r->error_route, undef,
    'returns undef for no error route registered' );

$routes->spew(<<~EOF
    @ not_found C N
    @ server_error C E
    EOF
);
$r = Minima::Router->new;
$r->read_file($routes);
my $error_r = $r->error_route;
is( $error_r->{controller}, 'C', 'returns correct error controller' );
is( $error_r->{action}, 'E', 'returnscorrect error action' );

my $match = $r->match('/');
is( $match->{controller}, 'C', 'returns correct not found controller' );
is( $match->{action}, 'N', 'returns correct not found action' );

$routes->spew(<<~EOF
    * / C H
    EOF
);
$r->read_file($routes);
$match = $r->match('/');
is( $match->{controller}, 'C', 'returns correct controller match' );
is( $match->{action}, 'H', 'returns correct action match' );

done_testing;
