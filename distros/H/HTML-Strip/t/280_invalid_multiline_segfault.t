use Test::More tests => 2;
use Test::Exception;

use HTML::Strip;

# test for RT#41035
my $hs = HTML::Strip->new();

ok( $hs->parse('<b>1</b><li>') );
lives_ok( sub { $hs->parse('ABC. DEFGH:') }, "no segfault" );

