use Test::Base;
use FindBin;
use lib "$FindBin::Bin/lib";

plan tests => 2;

use Foo;

is( $Foo::data, 'export function', 'export ok' );
is( Foo->method, 'object method', 'clean exported function ok');
