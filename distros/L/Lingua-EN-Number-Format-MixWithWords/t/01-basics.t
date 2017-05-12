#!perl

use 5.010;
use strict;
use warnings;
use Lingua::EN::Number::Format::MixWithWords qw(format_number_mix);
use Test::More 0.96;

sub test_format {
    my (%args) = @_;
    my $name = $args{name} // "num=$args{args}{num}";

    $args{args}{scale} //= 'short';
    #diag explain $args{args};
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
            if (ref($args{res}) eq 'Regexp') {
                like($res, $args{res}, "result");
            } else {
                is($res, $args{res}, "result");
            }
        }
    };
}

test_format args=>{num => 0}, res => '0';
test_format args=>{num => 1}, res => '1';
test_format args=>{num => -1.1}, res => '-1.1';
test_format args=>{num => 23}, res => '23';
test_format args=>{num => 230}, res => '230';
test_format args=>{num => 2300}, res => '2,300';
test_format args=>{num => 2400, min_format=>1e3}, res => '2.4 thousand';
test_format args=>{num => 2352001, min_format=>1e9}, res => '2,352,001';
test_format args=>{num => 2352000}, res => '2.352 million';
test_format args=>{num => -2352000, num_decimal=>2}, res => '-2.35 million';
test_format args=>{num => 1234567, num_decimal=>0}, res => '1 million';
test_format args=>{num => 1000000, }, res => '1 million';
test_format args=>{num => 900000, }, res => '900,000';
test_format args=>{num => -900000, min_fraction=>0.9}, res => '-0.9 million';
test_format args=>{num => 1234567}, res => '1.234567 million';

# 2013-09-11, fudged temporarily, failing reports on CT
#test_format name=>'rounding large (large number not rounded)',
#    args=>{num => 1.01e17, min_format=>1e20, num_decimal=>20},
#    res => qr/^1\.01e\+0*17$/i;
#test_format name=>'rounding large (num_decimal limited)',
#    args=>{num => 1.000000000000001e8, min_format=>1e20, num_decimal=>20},
#    res => '100,000,000';


test_format name=>'short 1', args=>{num => 1.2e15}, res => '1.2 quadrillion';
test_format name=>'long 1', args=>{num => 1.3e15, scale=>'long'},
    res => '1.3 billiard';

DONE_TESTING:
done_testing();
