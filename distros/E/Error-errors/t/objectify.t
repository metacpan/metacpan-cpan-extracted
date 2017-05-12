use Test::More tests => 2;

use errors;

try {
    die "Try dying";
}
catch Exception with {
    pass "Caught string error";
    is ref, 'RuntimeError', 'Unknown error becomes RuntimeError';
};
