#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use JSON::Color qw(encode_json);

subtest "basics" => sub {
    local $ENV{JSON_COLOR_COLOR_THEME};
    like(encode_json("1"), qr/\e\[/);
};

subtest "NO_COLOR env" => sub {
    local $ENV{JSON_COLOR_COLOR_THEME};
    local $ENV{NO_COLOR} = 1;
    my $true = bless(\(my $o = 1), "JSON::PP::Boolean");
    unlike(encode_json([[], {}, "foo", 3.14, undef, $true]), qr/\e\[/);
};

done_testing;
