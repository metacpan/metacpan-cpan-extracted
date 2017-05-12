use Test::More tests => 1;

use errors;
use errors -class => 'Foo';
use errors -class => 'Bar';
use errors -class => 'Baz';

try {
    throw Foo "Oh foo";
}
catch Bar with {
    fail "Fail except";
    return;
}
otherwise {
    pass "Pass otherwise";
};
