# This test is meant to exercise all the possible ways that parsing
# can fail, and also check that correct, yet weird or stupid inputs
# are not marked as invalid.

use warnings;
use strict;
use Test::More;
use JSON::Parse qw/valid_json validate_json/;

# https://github.com/benkasminbullock/JSON-Parse/issues/2

my $fdegir1 = <<'EOF';
{
"gav": {
"groupId": "mygroup",
"artifactId": "myartifact"
"version": "1.0"
}
}
EOF

ok (! valid_json ($fdegir1));
eval {
    validate_json ($fdegir1);
};
ok ($@, "validate_json dies");
like ($@, qr/line 5/i, "line number OK");

my $empty = '  ';
run_fail_like ($empty, qr/unexpected end of input/i);

my $undef = undef;
ok (! valid_json ($undef));
eval {
    no warnings 'uninitialized';
    validate_json ($undef);
    use warnings 'uninitialized';
};
ok ($@, "undef input dies");
like ($@, qr/empty input/i, "flagged as empty input");

#   ____                                                      _ 
#  / ___|___  _ __ ___  _ __ ___   __ _ ___    __ _ _ __   __| |
# | |   / _ \| '_ ` _ \| '_ ` _ \ / _` / __|  / _` | '_ \ / _` |
# | |__| (_) | | | | | | | | | | | (_| \__ \ | (_| | | | | (_| |
#  \____\___/|_| |_| |_|_| |_| |_|\__,_|___/  \__,_|_| |_|\__,_|
#                                                              
#            _                 
#   ___ ___ | | ___  _ __  ___ 
#  / __/ _ \| |/ _ \| '_ \/ __|
# | (_| (_) | | (_) | | | \__ \
#  \___\___/|_|\___/|_| |_|___/
#                             


# Test comma and colon parsing.

my $unknown_character = qr/unexpected character/i;
my $bad_comma_1 = '{,"bad":"bad"}';
run_fail_like ($bad_comma_1, $unknown_character);
my $bad_comma_array = '[,"bad","bad"]';
run_fail_like ($bad_comma_array, $unknown_character);
my $bad_comma_2 = '{"bad",:"bad"}';
run_fail_like ($bad_comma_2, $unknown_character);
my $bad_comma_3 = '{"bad":,"bad"}';
run_fail_like ($bad_comma_3, $unknown_character);
my $bad_comma_4 = '{"bad":"bad",}';
run_fail_like ($bad_comma_4, $unknown_character);
my $bad_comma_5 = '["bad","bad",]';
run_fail_like ($bad_comma_5, $unknown_character);
my $no_comma_array = '["bad" "bad"]';
run_fail_like ($no_comma_array, $unknown_character);
# Single-element array OK
run_ok ('["bad"]');
# Empty array OK
run_ok ('[]');
# Empty object OK
run_ok ('{}');
# Check the checking of final junk
my $too_many_end_braces = '{"bad":"bad"}}';
run_fail_like ($too_many_end_braces, $unknown_character);
my $too_many_end_brackets = '["bad","bad"]]';
run_fail_like ($too_many_end_brackets, $unknown_character);

run_fail_like ('{"bad":"forgot the end quotes}', qr/end of input/i);
# Bug in "get_key_string" found by randomtest
run_fail_like ("[\"\0]", $unknown_character);

# See what happens when we send a string with a null byte.

my $contains_null = '["' . "pupparoon\0\0 baba". '"]';
run_fail_like ($contains_null, qr/unexpected.*0x00/i);

# See what happens when we send a string with a disallowed byte.

my $contains_junk = '["' . chr (07) . '"]';
run_fail_like ($contains_junk, qr/unexpected.*0x07/i);

my $contains_escaped_null = '["\u0000"]';
run_ok ($contains_escaped_null);

my $contains_escaped_junk = '["\u0007"]';
run_ok ($contains_escaped_junk);

# Don't fail on pointless whitespace.

my $contains_silly_whitespace = <<EOF;

{
\r\n"why"   
:
\t"do"\t
}
EOF
run_ok ($contains_silly_whitespace);

# Throw an error with an unknown escape.

my $unknown_escape_1 = '["\a"]';
run_fail_like ($unknown_escape_1, $unknown_character);

# Test all the JSON escapes at once. Note here that \\\\ turns into \\
# after Perl has finished with it.

run_ok ('["\t\f\b\r\n\\\\\"\/"]');

my $bad_literal = '[truk]';
run_fail_like ($bad_literal, qr/unexpected character 'k'/i);

#  _   _                 _                     
# | \ | |_   _ _ __ ___ | |__   ___ _ __ ___   
# |  \| | | | | '_ ` _ \| '_ \ / _ \ '__/ __|  
# | |\  | |_| | | | | | | |_) |  __/ |  \__ \_ 
# |_| \_|\__,_|_| |_| |_|_.__/ \___|_|  |___(_)
#                                             

# Bad numbers.

my $double_minus = '[--1]';
run_fail_like ($double_minus, $unknown_character);

my $leading_zero = '[01]';
run_fail_like ($leading_zero, $unknown_character);

my $leading_plus = '[+1]';
run_fail_like ($leading_plus, $unknown_character);

my $double_exp_plus = '[0.1e++3]';
run_fail_like ($double_exp_plus, $unknown_character);

my $double_exp_minus = '[0.1e--3]';
run_fail_like ($double_exp_minus, $unknown_character);

my $misplaced_minus = '[0.1e1-3]';
run_fail_like ($misplaced_minus, $unknown_character);

my $bad_double = '[1.0e1.0]';
run_fail_like ($bad_double, $unknown_character);

my $ending = '[1234567';
run_fail_like ($ending, qr/unexpected end of input/i);
# Don't accept an isolated minus sign.
my $wsnumber = '[[null, true, -,   7965, 58]]';
run_fail ($wsnumber);

run_fail ('[43E+]');

# Numbers we accept.

run_ok ('[1.0e4]');
run_ok ('[1.0e+4]');
run_ok ('[1.0e-4]');
run_ok ('[0.0001e-4]');
run_ok ('[0e0]');
run_ok ('[0e1]');
run_ok ('[0.2e10]');

run_fail_like ('["a":1]', qr/unexpected character.*':'/i);
run_fail_like ('{1,2,3}', qr/unexpected character '1' parsing object/i);
run_fail_like ('[1,2,3}', qr/unexpected character.*'}'/i);
run_fail_like ('["\z"]', $unknown_character);
run_fail_like ('{"go":{"buddy":{"go":{"buddy":', qr/unexpected end of input/i);
run_fail_like ('{"gobuggs}', qr/unexpected end of input parsing/i);

run_fail_like ('["\uNOTHEX"]', qr/unexpected character 'N'/i);

run_fail_like ('["\uABC', qr/unexpected end of input/i);

run_fail_like ('["\uD834monkey\uDD1E"]', qr/unexpected character 'm'/i);
# This checks the string-length-checking code.
run_fail_like ('["\udc00???"]', qr/Unexpected end of input parsing unicode escape starting from byte 3/);

my $bad_plus = '[1.0e1+0]';
run_fail_like ($bad_plus, qr/unexpected character/i);
run_fail ('{"baba":6-3}');
run_fail_like ('{"baba":6.', qr/unexpected end of input parsing number/i);
run_fail_like ("{\"baba\":6.\0", qr/unexpected character.*parsing number/i);

# Bare values.

run_ok ('"clive"');

TODO: {
    local $TODO = 'known bugs';
};
done_testing ();
exit;

# Run the validator on $json with the expectation of getting an error
# which looks like $expected.

sub run_fail_like
{
    my ($json, $expected) = @_;
    my $error = run_fail ($json);
    like ($error, $expected,
	  "Got expected error '$expected' parsing '$json'");
}

# Run the test on $json with the expectation of it being invalid.

sub run_fail
{
    my ($json) = @_;
    ok (! valid_json ($json), "Error detection for '$json' with 'valid_json'");
    eval {
	validate_json ($json);
    };
    ok ($@, "Error detection for '$json' with 'validate_json'");
    return $@;
}

# Run the test on $json with the expectation of it being valid. This
# is for testing that kooky inputs don't cause failures.

sub run_ok
{
    my ($json) = @_;
    ok (valid_json ($json), "Parsing of '$json' with 'valid_json' succeeded");
    eval {
	validate_json ($json);
    };
    ok (! $@, "Parsing of '$json' with 'validate_json' succeeded");
    note ($@);
}
