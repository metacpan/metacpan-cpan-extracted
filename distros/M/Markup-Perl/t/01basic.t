use blib;
use strict;
use vars qw($perl $output $test_file $test_result);

use Test::More tests => 9;

$perl = $^X;
isnt($perl, '', "perl executable found: [$perl]");

$output = `$perl -e'print 1;'`;
ok($output, "perl executable can be run: [$output]");

my $test_file = 't/basic1.xml';
ok(-e $test_file, "test file found: [$test_file]");

$output = `$perl $test_file`;
ok($output, "running $test_file produces some output: [".length($output)." bytes]");

($test_result) = $output =~ m{<h1>(.*?)</h1>};
is($test_result, '0123456789', "<perl>print (0..9)</perl> code can be executed: [$test_result]");

($test_result) = $output =~ m{(<p>.*?</p>)}s;
is($test_result, "<p>\nplain text\n</p>", "plain text prints ok: [$test_result]");

($test_result) = $output =~ m{<h2>(.*?)</h2>};
is($test_result, 'abcdef', "prints across two <perl> blocks ok: [$test_result]");

($test_result) = $output =~ m{<h3>(.*?)</h3>};
is($test_result, 'defghi', "print from a subroutine in a diferent <perl> block ok: [$test_result]");

($test_result) = $output =~ m{<h4>(.*?)</h4>};
is($test_result, 'bang! bang! bang! ', "print across looped <perl> blocks is ok: [$test_result]");

print $output;
__END__