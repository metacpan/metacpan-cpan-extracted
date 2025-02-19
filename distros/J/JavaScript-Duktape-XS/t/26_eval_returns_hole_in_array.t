use strict;
use warnings;

use Test::More;

use blib;

use JavaScript::Duktape::XS;

my $js = JavaScript::Duktape::XS->new();

my $got = $js->eval('var foo = []; foo[1] = 123; foo');

is_deeply(
    $got,
    [undef, 123],
    '[(empty), 123]',
) or diag explain $got;

$got = $js->eval('var foo = []; foo[1] = undefined; foo');

is_deeply(
    $got,
    [undef, undef],
    '[(empty), undefined]',
) or diag explain $got;

$got = $js->eval('[undefined, undefined]');

is_deeply(
    $got,
    [undef, undef],
    '[undefined, undefined]',
) or diag explain $got;

done_testing;
