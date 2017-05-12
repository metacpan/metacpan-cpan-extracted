use warnings;
use Test::More tests => 2;

use errors;
use errors -class => 'Foo';
use errors -class => 'Bar';

try {
    throw Foo "Error 1";
}
catch Bar with {
    fail "catch incorrect error";
}
catch Exception with {
    pass "catch correct error";
    ok $_[0]->isa('Foo'), "It's a Foo!";
}
catch Foo with {
    fail "Don't catch twice";
}
except {
    fail "incorrect except clause";
}
otherwise {
    fail "incorrect otherwise clause";
};
