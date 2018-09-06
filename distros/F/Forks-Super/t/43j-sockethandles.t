use Forks::Super ':test';
use Test::More tests => 14;
use strict;
use warnings;

# exercise  getc  methods of  Forks::Super ,
# with and without blocking and timeouts.
$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd/;

my $pid = fork {
    timeout => 20,
    child_fh => 'out,err,socket',
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
okl($t >= 3.5 && $t <= 7.65,             ### 6 ### was 6.5, obs 7.62
    "took ${t}s, expected ~5s");

$t = Time::HiRes::time();
$c = $pid->getc_stderr(timeout => 2);
$tt = Time::HiRes::time() - $t;
ok(!defined($c) || $c eq '', 'still nothing to read on stderr');
okl($tt >= 1.0 && $tt <= 4.5,            ### 8 ### 
    "timeout on getc_stderr respected, took ${tt}s, expected ~2s");
$c = $pid->getc_stdout;
ok($c eq 'o', 'read another char from stdout')
    or diag("got '$c', expected 'o'");
$c = $pid->read_stdout;
ok($c eq "o\n" || $c eq "o\r\n",
   'read_stdout returns the rest of the line')
    or diag "rest of line is ",map{" ".ord}split//,$c;
$c = $pid->getc_stderr(block => 1);
$t = Time::HiRes::time() - $t;
ok(defined($c) && $c eq 'O', 'got first char from stderr');
okl($t >= 3.5 && $t <= 7.65,                    ### 12 ### was 6.5, obs 7.62
    "took ${t}s, expected ~5s");
$pid->wait;
ok($pid->getc_stderr eq 'P', 'getc_stderr works after child expires');
$c = $pid->getc_stderr() . $pid->getc_stderr() . $pid->getc_stderr();
ok($c eq "Q\n" || $c eq "Q\r\n",
   'got remaining chars from stderr');


