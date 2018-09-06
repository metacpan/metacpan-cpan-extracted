use Forks::Super ':test';
use Test::More tests => 14;
use strict;
use warnings;

# exercise  getc  methods of  Forks::Super ,
# with and without blocking and timeouts.
$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd/;

my $pid = fork {
    timeout => 20,
    child_fh => 'out,err,pipe',
    sub => sub {
	sleep 5;
	print STDOUT "foo\n";
	sleep 5;
	print STDERR "OPQ\n";
    }
};


my $c = $pid->getc_stdout();
ok(!defined($c) || $c eq '', 'nothing to read from stdout yet');
$c = $pid->getc_stderr();
ok(!defined($c) || $c eq '', 'nothing to read from stderr yet');
my $t = Time::HiRes::time();
$c = $pid->getc_stdout(timeout => 2);
my $tt = Time::HiRes::time() - $t;
ok(!defined($c) || $c eq '', 'still nothing to read');
okl($tt >= 1.0 && $tt <= 4.5,             ### 4 ###
    "timeout on getc_stdout respected, took ${tt}s expected ~2s");

$c = $pid->getc_stdout(block => 1);
$t = Time::HiRes::time() - $t;
ok($c eq 'f', 'got first char from stdout');
# this should take ~5s. openbsd consistently comes in around 7.48-7.49?
if ($^O =~ /openbsd/i) {
    diag("took ${t}s for first getc from stdout, expected ~5s");
}
ok($t >= 3.25 && $t <= 7.65,                         ### 6 ### was 6.5, obs 7.49
   "took ${t}s, expected ~5s");				     # was 3.5, obs 3.33

$t = Time::HiRes::time();
$c = $pid->getc_stderr(timeout => 2);
$tt = Time::HiRes::time() - $t;
ok(!defined($c) || $c eq '', 'still nothing to read on stderr');
ok($tt >= 1.0 && $tt <= 3.0, 'timeout on getc_stderr respected');
my $cc = $pid->getc_stdout;
ok($cc eq 'o', 'read another char from stdout') or diag("2nd char was '$cc'");
$c = $pid->read_stdout;
ok($c eq "o\n" || $c eq "o\r\n", 'read_stdout returns the rest of the line');
$c = $pid->getc_stderr(block => 1);
$t = Time::HiRes::time() - $t;

# tests 11,13,14 failure point on solaris
ok(defined($c) && $c eq 'O',                         ### 11 ###
   'got first char from stderr');
ok($t >= 3.5 && $t <= 6.8, 			     ### 12 ### was 6.5,obs 6.75
   "took ${t}s to read first char, expected ~5s");
$pid->wait;
ok($pid->getc_stderr eq 'P',                         ### 13 ###
   'getc_stderr works after child expires');
$c = $pid->getc_stderr() . $pid->getc_stderr()
    . ($pid->getc_stderr() || '');
ok($c eq "Q\n" || $c eq "Q\r\n",                     ### 14 ###
   'got remaining chars from stderr');

