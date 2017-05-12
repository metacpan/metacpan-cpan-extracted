use Test::More tests => 5;
use strict;
use warnings;
use errors;

try {
    pass "Pass try 1";
    throw Exception("Error 1");
    fail "Fail try 1";
}
catch Exception with {
    my $e = shift;
    is ref($e), 'Exception', '$e contains proper object';
    is "$@", "Error 1", 'Stringify works';
    is $_->text, 'Error 1', 'value() method works';
}
except {
    fail 'Fail except 1';
}
otherwise {
    fail 'Fail otherwise 1';
}
finally {
    pass "Pass finally 1";
};
