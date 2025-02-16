use Test2::V0;

use HTTP::SecureHeaders;

my @OK = (
    "max-age=631138519",
    "max-age=631138519; includeSubDomains",
    "max-age=631138519; includeSubDomains; preload",
    "max-age=631138519; preload",

    "max-age=631138519;includeSubDomains",
    "max-age=631138519 ;includeSubDomains",
    "max-age=631138519 ; includeSubDomains",
);

my @NG_for_simplicity = (
    "max-age='631138519'", # quote
    "MAX-AGE=631138519",
    "includeSubDomains; max-age=631138519",
    "max-age=631138519; includeSubDomains; includeSubDomains",
);

my @NG = (
    "age=631138519", # invalid directive_name
    "max-age=631138519; includeSubDomains;", # last semicolon
    "includeSubDomains", # required max-age
    "preload", # required max-age
);

subtest 'OK cases' => sub {
    ok HTTP::SecureHeaders::check_strict_transport_security($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !HTTP::SecureHeaders::check_strict_transport_security($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
