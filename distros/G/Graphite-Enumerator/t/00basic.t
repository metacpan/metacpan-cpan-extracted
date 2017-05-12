use Test::More tests => 2;
use_ok('Graphite::Enumerator');
my $g = Graphite::Enumerator->new(
    host => 'localhost',
    basepath => 'main',
);
is( $g->host, 'http://localhost/', 'host method returns full URL' );
