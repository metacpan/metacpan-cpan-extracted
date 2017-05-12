use Test::More tests => 8;

use errors -class => 'FooError';
use errors -class => 'FooFooError', -isa => 'FooError';

BEGIN {
    ok(not(defined &try), '-class syntax does not import try stuff');
}

use errors;

try {
    throw FooError('foo occurred');
}
catch FooError with {
    pass "Caught FooError";
    is $@->text, 'foo occurred', 'Error text is correct';
};

try {
    throw FooFooError('foo foo occurred');
}
catch FooError with {
    pass "Caught FooFooError";
    is ref($@), 'FooFooError', 'error is correct class';
    ok $@->isa('FooError'), 'error isa FooError';
    ok $@->isa('Exception'), 'error isa Exception';
    ok $@->can('throw'), 'error can throw';
}
except {
    fail "Caught FooFooError in wrong place";
};

