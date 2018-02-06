use Forks::Super qw(:test_CA overload);
use Forks::Super::Util qw(is_socket is_pipe);
use Test::More tests => 14;
use strict;
use warnings;

$Forks::Super::SOCKET_READ_TIMEOUT = 0.25;

# test blocked and unblocked reading for file handles.

my $pid = fork {
    child_fh => "out,err,block",
    sub => sub {
	print STDERR "foo\n";
	sleep 5;
	print STDOUT "bar\n";
	sleep 5;
	print STDOUT "baz\n";
    }
};

ok(isValidPid($pid), "$pid is valid pid");
SKIP: {
    if (Forks::Super::Config::CONFIG('filehandles') == 0) {
	skip "filehandles are unconfigured, ignore handle type test", 1;
    }
    ok(!is_socket($pid->{child_stdout}) && !is_pipe($pid->{child_stdout}), 
       "ipc with filehandles");
}
sleep 1;
my $t0 = Time::HiRes::time();
my $err = Forks::Super::read_stderr($pid);
my $t1 = Time::HiRes::time() - $t0;
ok($err =~ /^foo/, "read stderr");
okl($t1 < 1.40, "read blocked stderr fast ${t1}s, expected <1s");  ### 4 ### obs 1.38

my $out = $] >= 5.008008 ? <$pid> : $pid->read_stdout();
my $t2 = Time::HiRes::time() - $t0;
ok($out =~ /^bar/, "read stdout");
okl($t2 > 2.05, "read blocked stdout ${t2}s, expected ~4s");

$out = Forks::Super::read_stdout($pid, "block" => 0);
my $t3 = Time::HiRes::time() - $t0;
my $t32 = $t3 - $t2;
ok(!defined($out) || (defined($out) && $out eq ''), 
   "non-blocking read on stdout returned empty");
okl($t32 <= 1.0, "non-blocking read took ${t32}s, "
	      . "expected ~${Forks::Super::SOCKET_READ_TIMEOUT}s");

$out = Forks::Super::read_stdout($pid);
my $t4 = Time::HiRes::time() - $t0;
my $t43 = $t4 - $t3;
ok($out =~ /^baz/, "successful blocking read on stdout");
okl($t43 > 3.3, "read blocked stdout ${t43}s, expected ~5s");

#### no more input on STDOUT or STDERR

$err = Forks::Super::read_stderr($pid);
my $t5 = Time::HiRes::time() - $t0;
my $t54 = $t5 - $t4;
ok(!defined($err) || $err eq '',                         ### 11 ###
   "blocking read on empty stderr returns empty");
okl($t54 <= 5.0, 
   "blocking read on empty stderr can take a moment ${t54}s, expected ~3s");

# print "\$err = $err, time = $t5, $t54\n";

$out = Forks::Super::read_stdout($pid, "block" => 0);
my $t6 = Time::HiRes::time() - $t0;
my $t65 = $t6 - $t5;
ok(!defined($out) || $out eq "",                         ### 13 ###
   "non-blocking read on empty stdout returns empty");
okl($t65 <= 1.3, 
   "non-blocking read on empty stdout fast ${t65}s, expected <1.0s");

# print "\$out = $out, time = $t6, $t65\n";


