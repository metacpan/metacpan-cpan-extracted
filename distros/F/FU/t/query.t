use v5.36;
use Test::More;
use FU::Util qw/query_decode query_encode/;
use experimental 'builtin';

is_deeply
    query_decode('a&a&%c3%be=%26%3d%c3%be&a=3'),
    { a => [ builtin::true, builtin::true, 3 ], "\xfe" => "&=\xfe" };

ok !eval { query_decode('%10'); 1 };
like $@, qr/Invalid control character/;

is query_encode
    { a => builtin::true, b => undef, c => builtin::false, d => 'string', e => "&=\xfe" },
    'a&d=string&e=%26%3d%c3%be';

is query_encode
    { "\xfe" => [ 1, undef, 3, builtin::false, builtin::true ] },
    "%c3%be=1&%c3%be=3&%c3%be";

is_deeply
    query_decode('a=&a=&b=&c==x&d=x='),
    { a => ['', ''], b => '', c => '=x', d => 'x=' };

is query_encode { a => ['', '', \1], b => '', c => '=x', d => 'x=' }, 'a=&a=&a&b=&c=%3dx&d=x%3d';


sub FUTILTEST::TO_QUERY { '&'.($_[0][0] + 1) }

is query_encode
    { -ab => bless [2], 'FUTILTEST' },
    '-ab=%263';

done_testing;
