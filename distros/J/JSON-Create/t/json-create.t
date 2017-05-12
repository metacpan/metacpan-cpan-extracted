# This is a test for module JSON::Create.

# This part tests only data types, strings, hashes and arrays, with no
# Unicode characters in the strings.

use warnings;
use strict;
use Test::More;
use JSON::Create qw/create_json create_json_strict/;
use JSON::Parse qw/valid_json parse_json/;
for my $func (\&create_json, \&create_json_strict) {
    my %hash = ('a' => 'b');
    my $json_hash = &{$func} (\%hash);
    is ($json_hash, '{"a":"b"}', "json simple hash OK");
    my $hashhash = {a => {b => 'c'}, d => {e => 'f'}};
    my $json_hashhash = &{$func} ($hashhash);
    ok (valid_json ($json_hashhash), "json nested hash valid");
    like ($json_hashhash, qr/"a":\{"b":"c"\}/, "json nested hash OK part 1");
    like ($json_hashhash, qr/"d":\{"e":"f"\}/, "json nested hash OK part 2");

    # Arrays

    my $array = ['there', 'is', 'no', 'other', 'day'];
    my $json_array = &{$func} ($array);
    is ($json_array, '["there","is","no","other","day"]', "flat array JSON correct");
    my $nested_array = ['let\'s', ['try', ['it', ['another', ['way']]]]];
    my $json_nested_array = &{$func} ($nested_array);
    ok (valid_json ($json_nested_array), "Nested array JSON valid");
    is ($json_nested_array, '["let\'s",["try",["it",["another",["way"]]]]]', "Nested array JSON correct");

    my $numbers = [1,2,3,4,5,6];
    my $numbers_json = &{$func} ($numbers);
    is ($numbers_json, '[1,2,3,4,5,6]', "simple integers");
    my $fnumbers = [0.5,0.25];
    my $fnumbers_json = &{$func} ($fnumbers);
    is ($fnumbers_json, '[0.5,0.25]', "round floating point numbers");

    my $negnumbers = [-1,2,-3,4,-5,6];
    my $negnumbers_json = &{$func} ($negnumbers);
    is ($negnumbers_json, '[-1,2,-3,4,-5,6]', "negative numbers OK");

    my $bignegnumbers = [-1000000,2000000,-300000000];
    my $bigneg_json = &{$func} ($bignegnumbers);
    is ($bigneg_json, '[-1000000,2000000,-300000000]', "big negative numbers OK");

    #my $code = sub {print "She's often inclined to borrow somebody's dreams till tomorrow"};
    #print $code;
    #my $json_code = &{$func} ($code);
    #print $json_code;

    # Undefined should give us the bare value "null".
    run (undef, 'null', $func);
    run ({'a' => undef},'{"a":null}', $func);

    # Hash to numbers.

    my $h2n = {
	a => 1,
	b => 2,
	c => 4,
	d => 8,
	e => 16,
	f => 32,
	g => 64,
	h => 128,
	i => 256,
	j => 512,
	k => 1024,
	l => 2048,
	m => 4096,
	n => 8192,
	o => 16384,
	p => 32768,
	q => 65536,
	r => 131_072,
	s => 262_144,
	t => 524_288,
	u => 1_048_576,
	v => 2_097_152,
	w => 4_194_304,
	x => 8_388_608,
	y => 16_777_216,
	z => 33_554_432,
	A => 67_108_864,
	B => 134_217_728,
	C => 268_435_456,
	D => 536_870_912,
	E => 1_073_741_824,
    };

    run ($h2n, \&alnums, $func);

    my $backslasht = {monkey => "\t"};
    run ($backslasht, '{"monkey":"\t"}', $func, "tab escape");
    my $controlchar = {cc => "\x01"};
    run ($controlchar, '{"cc":"\u0001"}', $func, "ASCII control character");
    my $weirdstring = "\t\r\n\x00";
    run ({in => $weirdstring}, '{"in":"\t\r\n\u0000"}', $func, "string containing a nul byte");
}

done_testing ();
exit;
# Local variables:
# mode: perl
# End:

sub run
{
    my ($input, $test, $func, $name) = @_;
    if (! defined $name) {
	$name = '';
    }
    else {
	$name = " - $name";
    }
    my $output;
    eval {
	$output = &{$func} ($input);
    };
    #    print "$output\n";
    ok (! $@, "no errors on input $name");
    ok (valid_json ($output), "output is valid JSON $name");
    if (ref $test eq 'CODE') {
	&{$test} ($input, $output);
    }
    elsif (ref $test eq 'Regexp') {
	like ($output, $test, "input looks as expected $name");
    }
    elsif (! defined $test) {
	# skip this test
    }
    else {
	# Assume string
	is ($output, $test, "output is what was expected $name");
    }
    return;
}

sub alnums
{
    my ($input, $output) = @_;
    my $stuff = parse_json ($output);
    my $num = 1;
    for my $letter ('a'..'z') {
	ok ($stuff->{$letter} == $num, "$letter is $num");
	$num *= 2;
    }
}
