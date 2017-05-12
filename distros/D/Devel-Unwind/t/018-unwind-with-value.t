use warnings;
use strict;

use Test::More;
use Scalar::Util 'blessed';
use Devel::Unwind;

my $entered_do;
mark TOPLEVEL {
    eval {
        unwind TOPLEVEL (bless [], "FOO");
        fail "Execution after die";
        1;
    } or do {
        fail "Execution in do block";
    };
    fail "Execution after eval but inside mark block";
    1;
} or do {
    $entered_do = 1;
    ok(blessed($@) && ref($@) eq "FOO", '$@ is a blessed reference');
};
ok($entered_do, "Entered do block");
undef $entered_do;

mark TOPLEVEL {
    unwind TOPLEVEL 1..5 if 1;
    1;
} or do {
    $entered_do = 1;
    like($@,qr/^12345\b/, '$@ is "12345"');
};
ok($entered_do, "Entered second do block");
done_testing;
