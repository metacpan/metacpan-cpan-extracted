use Test::More skip_all => tests => 4;
use errors;

try {
    pass "Pass try test 1";
    try {
        pass "Pass try test 2";
        throw Error("error 2");
        fail "Fail try test 2";
    }
    except {
        my $e = shift;
        pass "Pass except test 2";
        is $e->text, 'error 2', 'Caught correct error 2';
    };
    pass "After try test 2";
    throw Error("error 1");
}
except {
    my $e = shift;
    is $e->text, 'error 1', 'Caught correct error 1';
};
