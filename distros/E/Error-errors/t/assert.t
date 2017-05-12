use Test::More tests => 3;

use errors;

ok assert(1, '1 is ok'), 'assert is exported and works on true';

try {
    assert(0, '0 is not ok'), 'assert is exported and works on true';
}
catch AssertionError with {
    pass "Caught AssertionError";
    is "$@", '0 is not ok', 'Error msg from assertion is good';
};
