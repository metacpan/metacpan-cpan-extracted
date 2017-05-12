#!perl

use 5.010;
use strict;
use warnings;
use Lingua::ID::Number::Format::MixWithWords qw(format_number_mix);
use Test::More 0.98;

sub test_format {
    my (%args) = @_;
    my $name = $args{name} // "num=$args{args}{num}";

    subtest $name => sub {
        my $res;
        my $eval_err;
        eval { $res = format_number_mix(%{$args{args}}) }; $eval_err = $@;

        if ($args{dies}) {
            ok($eval_err, "dies");
        } else {
            ok(!$eval_err, "doesn't die") or diag $eval_err;
        }

        if (exists $args{res}) {
            is($res, $args{res}, "result");
        }
    };
}

test_format args=>{num => 0}, res => '0';
test_format args=>{num => 1}, res => '1';
test_format args=>{num => -1.1}, res => '-1,1';
test_format args=>{num => 23}, res => '23';
test_format args=>{num => 230}, res => '230';
test_format args=>{num => 2300}, res => '2.300';
test_format args=>{num => 2400, min_format=>1e3}, res => '2,4 ribu';
test_format args=>{num => 2352001, min_format=>1e9}, res => '2.352.001';
test_format args=>{num => 2352000}, res => '2,352 juta';
test_format args=>{num => -2352000, num_decimal=>2}, res => '-2,35 juta';
test_format args=>{num => 1234567, num_decimal=>0}, res => '1 juta';
test_format args=>{num => 1000000, }, res => '1 juta';
test_format args=>{num => 900000, }, res => '900.000';
test_format args=>{num => -900000, min_fraction=>0.9}, res => '-0,9 juta';
test_format args=>{num => 1234567}, res => '1,234567 juta';

DONE_TESTING:
done_testing();
