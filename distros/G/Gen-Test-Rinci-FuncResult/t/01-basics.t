#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';

use Capture::Tiny qw(capture);
use File::Slurp::Tiny qw(write_file);
use File::Temp qw(tempfile);
use Test::More 0.98;

do "$Bin/template";

ok(test_divide(args=>{a=>6, b=>3}, result=>2));
ok(test_divide(args=>{a=>6, b=>0}, dies=>1));
ok(test_divide(args=>{a=>0, b=>0}, status=>500));
test_fail(q(test_divide(args=>{a=>6, b=>3}, status=>100)),
          qr/not ok.+status/, 'wrong status');
test_fail(q(test_divide(args=>{a=>6, b=>3}, dies=>1)),
          qr/not ok.+dies/, 'wrong dies (should die but didnt)');
test_fail(q(test_divide(args=>{a=>6, b=>0}, dies=>0)),
          qr/not ok.+die/, 'wrong dies (shouldnt die but did)');
test_fail(q(test_divide(args=>{a=>6, b=>3}, result=>4)),
          qr/not ok.+result/, 'wrong result');

DONE_TESTING:
done_testing;

sub test_fail {
    my ($code, $re_stdout, $name) = @_;

    my ($stdout, $stderr, $exit) = capture {
        my ($fh, $filename) = tempfile();
        write_file($filename, qq(do "$Bin/template"; ).$code);
        system $^X, "-I$Bin/..", $filename;
    };

    like($stdout, $re_stdout, $name);
}
