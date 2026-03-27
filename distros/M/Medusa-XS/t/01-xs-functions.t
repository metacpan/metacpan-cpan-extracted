#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Test XS utility functions

BEGIN {
    use_ok( 'Medusa::XS' ) || BAIL_OUT("Cannot load Medusa::XS");
}

# ------------------------------------------------------------------ #
# Test generate_guid()                                                #
# ------------------------------------------------------------------ #

{
    my $guid = Medusa::XS::generate_guid();
    ok(defined $guid, 'GUID is defined');
    is(length($guid), 36, 'GUID is 36 characters');
    like($guid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i, 
         'GUID matches UUID v4 format');
    
    my $guid2 = Medusa::XS::generate_guid();
    isnt($guid, $guid2, 'Two GUIDs are different');
}

# ------------------------------------------------------------------ #
# Test format_time()                                                  #
# ------------------------------------------------------------------ #

{
    my $time = Medusa::XS::format_time();
    ok(defined $time, 'format_time default: defined');
    ok(length($time) > 0, 'format_time default: not empty');
    like($time, qr/^\w{3}\s+\w{3}\s+\d+\s+\d+:\d+:\d+\s+\d{4}$/, 'format_time default: matches asctime format');
}

{
    my $time = Medusa::XS::format_time(1, '%Y-%m-%d');
    ok(defined $time, 'format_time custom: defined');
    like($time, qr/^\d{4}-\d{2}-\d{2}$/, 'format_time custom: matches format');
}

{
    my $time = Medusa::XS::format_time(1, '%H:%M:%S.%ms');
    ok(defined $time, 'format_time ms: defined');
    like($time, qr/^\d{2}:\d{2}:\d{2}\.\d{3}$/, 'format_time ms: includes milliseconds');
}

{
    my $gm = Medusa::XS::format_time(1);  # gmtime
    my $lt = Medusa::XS::format_time(0);  # localtime
    ok(defined $gm, 'gmtime format works');
    ok(defined $lt, 'localtime format works');
}

# ------------------------------------------------------------------ #
# Test collect_caller_stack()                                         #
# ------------------------------------------------------------------ #

{
    my $stack = Medusa::XS::collect_caller_stack();
    ok(defined $stack, 'Caller stack is defined');
    like($stack, qr/^([\w:]+:\d+)?(->([\w:]+):\d+)*$|^$/, 'Stack matches expected format or is empty');
}

sub helper_for_stack_test {
    return Medusa::XS::collect_caller_stack();
}

{
    my $stack = helper_for_stack_test();
    ok(defined $stack, 'Nested stack is defined');
    like($stack, qr/main:\d+/, 'Stack contains main package');
}

# ------------------------------------------------------------------ #
# Test clean_dumper()                                                 #
# ------------------------------------------------------------------ #

{
    my $input = '"hello"';
    my $output = Medusa::XS::clean_dumper($input);
    ok(defined $output, 'clean_dumper: output defined');
    is($output, '"hello"', 'clean_dumper: input returned unchanged');
}

{
    my $input = '{key => "value", foo => "bar"}';
    my $output = Medusa::XS::clean_dumper($input);
    is($output, $input, 'clean_dumper: preserves input as-is');
}

{
    my $input = '$VAR1 = "hello   world";';
    my $output = Medusa::XS::clean_dumper($input);
    like($output, qr/hello   world/, 'Whitespace inside quotes preserved');
    
    my $input2 = q{$VAR1 = 'single   quotes';};
    my $output2 = Medusa::XS::clean_dumper($input2);
    like($output2, qr/single   quotes/, 'Single quote strings preserved');
}

done_testing();
