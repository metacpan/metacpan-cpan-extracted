use Forks::Super ':test';
use Test::More tests => 14;
use strict;
use warnings;

# exercise  getc  methods of  Forks::Super ,
# with and without blocking and timeouts.
$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd|netbsd/i;

my $pid = fork {
    timeout => 20,
    child_fh => 'out,err',
    sub => sub {
	sleep 5;
	print STDOUT "foo\n";
	sleep 5;
	print STDERR "OPQ\n";
    }
};


my $c = $pid->getc_stdout();
ok(defined($c) && $c eq '', 'nothing to read from stdout yet');
$c = $pid->getc_stderr();
ok(defined($c) && $c eq '', 'nothing to read from stderr yet');
my $t = Time::HiRes::time();
$c = $pid->getc_stdout(timeout => 2);
my $tt = Time::HiRes::time() - $t;
ok(defined($c) && $c eq '', 'still nothing to read');
okl($tt >= 1.0 && $tt <= 4.5,             ### 4 ###
    "timeout on getc_stdout respected, took ${tt}s expected ~2s");

$c = $pid->getc_stdout(block => 1);
$t = Time::HiRes::time() - $t;
ok($c eq 'f', 'got first char from stdout');
okl($t >= 3.5 && $t <= 7.65,              ### 6 ###
    "took ${t}s, expected ~5s");

$t = Time::HiRes::time();
$c = $pid->getc_stderr(timeout => 2);
$tt = Time::HiRes::time() - $t;
ok(defined($c) && $c eq '', 'still nothing to read on stderr');
ok($tt >= 1.0 && $tt <= 3.0, 'timeout on getc_stderr respected');
ok($pid->getc_stdout eq 'o', 'read another char from stdout');
ok($pid->read_stdout eq "o\n", 'read_stdout returns the rest of the line');
$c = $pid->getc_stderr(block => 1);
$t = Time::HiRes::time() - $t;
ok(defined($c) && $c eq 'O', 'got first char from stderr');
ok($t >= 3.5 && $t <= 6.8,                ### 12 ### obs 6.75s
   "took ${t}s to read first char, expected ~5s");
$pid->wait;
ok($pid->getc_stderr eq 'P', 'getc_stderr works after child expires');
ok($pid->getc_stderr() . $pid->getc_stderr() . $pid->getc_stderr() eq "Q\n",
   'got remaining chars from stderr');
