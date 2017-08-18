use warnings;
use strict;

use Test::More;

plan tests => 4;

use Dios;

class ArrowType {
    has Hash[Int => Str] %!B;
}

ok(        ArrowType->new({ B => { test => { 123 => 'dog'} } })   );
ok( !eval{ ArrowType->new({ B => { test => { cat => 'dog'} } }) } );


class MatchType { has Match[\d] $!B; }

ok(         MatchType->new({ B => 'cat1' })   );
ok( !eval { MatchType->new({ B => 'catA' }) } );


done_testing();

