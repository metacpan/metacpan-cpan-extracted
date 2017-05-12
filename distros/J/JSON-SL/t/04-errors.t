#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use JSON::SL;
use Data::Dumper;


# Idea taken from JSON::XS 02_error.t

sub test_invalid_string($) {
    my $garbage = shift;
    my $sl = JSON::SL->new();
    my $json = sprintf('{"ok_key":%s}', $garbage);
    eval { $sl->feed($json) };
    my $pretty = $json;
    my $replace = sub {
        my $c = $1;
        "\\x".sprintf("%02x",ord($c));
    };
    $pretty =~ s/([^\x{20}-\x{7e}])/&$replace/ge;
    ok($@, "Got error for invalid string '$pretty'");
}

test_invalid_string '+0';
test_invalid_string '.2';
test_invalid_string 'bare';
test_invalid_string 'naughty';

# we won't handle encoding errors, and frankly there's
# nowhere in the standard i'm seeing which explicitly forbids it.

test_invalid_string '00'; #we use json::xs for this anyway
test_invalid_string '01';
test_invalid_string '-0.';
test_invalid_string '-0e';
test_invalid_string '-e+1';

# now we're back to my own code again
test_invalid_string "\"\n\"";
test_invalid_string "\x01";

test_invalid_string [];

# JSON::XS has 0xa0 as a 'disallowed' character, however
# literal 0xa0 is perfectly allowed (and apparently permitted
# by JSON lint)


done_testing();