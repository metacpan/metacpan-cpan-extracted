#!perl -w
use strict;
use Test::More;
use JSON::Pointer::Syntax qw(is_array_numeric_index);

sub test_is_array_numeric_index {
    my ($token, $expect, $desc) = @_;
    my $actual = is_array_numeric_index($token);
    is($actual, $expect, $desc);
}

subtest "valid numeric index" => sub {
    test_is_array_numeric_index("0", 1, q{"0"});
    test_is_array_numeric_index("23", 1, q{"23"});
};

subtest "invalid numeric index" => sub {
    test_is_array_numeric_index("-23", 0, q{"-23"});
    test_is_array_numeric_index("foo", 0, q{"foo"});
    test_is_array_numeric_index("-", 0, q{"-"});
    test_is_array_numeric_index("", 0, q{""});
};

done_testing;

