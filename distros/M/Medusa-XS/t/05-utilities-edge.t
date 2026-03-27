#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Edge case tests for C utility functions (Phase 5)

BEGIN {
    use_ok( 'Medusa::XS' ) || BAIL_OUT("Cannot load Medusa::XS");
}

# ------------------------------------------------------------------ #
# generate_guid() edge cases                                          #
# ------------------------------------------------------------------ #

{
    my %seen;
    for (1..100) {
        my $guid = Medusa::XS::generate_guid();
        $seen{$guid}++;
    }
    is(scalar keys %seen, 100, 'generate_guid: 100 GUIDs are all unique');
}

# ------------------------------------------------------------------ #
# format_time() edge cases                                            #
# ------------------------------------------------------------------ #

{
    my $time = Medusa::XS::format_time(1, '');
    is($time, '', 'format_time: empty format returns empty string');
}

{
    my $time = Medusa::XS::format_time(1, '%ms-%ms');
    like($time, qr/^\d{3}-%ms$/, 'format_time: first %ms replaced');
}

# ------------------------------------------------------------------ #
# clean_dumper() edge cases                                           #
# ------------------------------------------------------------------ #

{
    my $output = Medusa::XS::clean_dumper('');
    is($output, '', 'clean_dumper: empty string returns empty');

    $output = Medusa::XS::clean_dumper('$VAR1 = ;');
    is($output, '$VAR1 = ;', 'clean_dumper: pass-through returns input unchanged');
}

{
    my $input = '{outer => {inner => [1, 2, 3]}}';
    my $output = Medusa::XS::clean_dumper($input);
    is($output, $input, 'clean_dumper: nested structures passed through');
}

{
    my $input = q{$VAR1 = "hello \"world\"";};
    my $output = Medusa::XS::clean_dumper($input);
    like($output, qr/hello \\"world\\"/, 'clean_dumper: escaped quotes preserved');
}

{
    my $input = q{$VAR1 = { 'key' => "value with   spaces" };};
    my $output = Medusa::XS::clean_dumper($input);
    like($output, qr/value with   spaces/, 'clean_dumper: spaces in double quotes preserved');
}

{
    my $input = '{ "key" => "value" }';
    my $output = Medusa::XS::clean_dumper($input);
    like($output, qr/"key" => "value"/, 'clean_dumper: input without $VAR1 passed through');
}

done_testing();
