use Forks::Super ':test';
use Test::More tests => 5;
use strict;
use warnings;

my ($pid,$out);
$ENV{XYZ} = "foo";
$pid = fork {
    child_fh => 'all',
    sub => sub { print $ENV{XYZ} },
#   env => { XYZ => 'bar' }
};
$pid->wait;
$out = $pid->read_stdout();

ok($ENV{XYZ} eq 'foo', "fork does not change parent environment");
ok($out eq 'foo', "child inherits parent environment");

$ENV{WXYZ} = 'quux';
$pid = fork {
    child_fh => 'all,block',
    sub => sub { eval { print $ENV{WXYZ}, $ENV{XYZ} } },
    env => { WXYZ => 'bar' }
};
ok(isValidPid($pid), "$$\\fork with env option launched");
ok($ENV{XYZ} eq 'foo' && $ENV{WXYZ} eq 'quux', 
   "fork does not change parent environment");

$pid->wait;
$out = $pid->read_stdout();
ok($out eq 'barfoo', "child respects env option")
    or diag("output was '$out', expected 'barfoo'");


