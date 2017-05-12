use Forks::Super qw(:test overload);
use Forks::Super::Util qw(is_socket);
use Test::More tests => 20;
use strict;
use warnings;

$Forks::Super::SOCKET_READ_TIMEOUT = 0.25;

# test blocked and unblocked reading for socket handles.

my $pid = fork {
    child_fh => "out,err,socket",
    sub => sub {
	print STDERR "foo\n";
	sleep 5;
	print STDOUT "bar\n";
	sleep 5;
	print STDOUT "baz\n";
	die "OK to die from child with socket based IPC, but don't exit.\n";
    }
};

ok(isValidPid($pid), "$pid is valid pid");
ok(is_socket($pid->{child_stdout}), "ipc with sockets");
sleep 1;
my $t0 = Time::HiRes::time();

my $err = Forks::Super::read_stderr($pid, "block" => 1);
my $t1 = Time::HiRes::time() - $t0;
ok($err =~ /^foo/, "read stderr");
okl($t1 <= 1.0, "read blocked stderr fast ${t1}s, expected <1s");     ### 4 ###

my $out = Forks::Super::read_stdout($pid, "block" => 1);   # this should block
my $t2 = Time::HiRes::time() - $t0;
ok($out =~ /^bar/, "read stdout");
okl($t2 > 2.95, "read blocked stdout ${t2}s, expected ~4s");

$out = Forks::Super::read_stdout($pid, "block" => 0);
my $t3 = Time::HiRes::time() - $t0;
my $t32 = $t3 - $t2;
ok(!defined($out), "non-blocking read on stdout returned empty");
okl($t32 <= 1.0, "non-blocking read took ${t32}s, "
                 . "expected ~${Forks::Super::SOCKET_READ_TIMEOUT}s");

$out = Forks::Super::read_stdout($pid, "block" => 1);
my $t4 = Time::HiRes::time() - $t0;
my $t43 = $t4 - $t3;
ok($out =~ /^baz/, "successful blocking read on stdout")
  or diag("Got \$out='$out'\nExpected /^baz/\n");
okl($t43 > 3.5, "read blocked stdout ${t43}s, expected ~5s");

#### no more input on STDOUT or STDERR

$err = Forks::Super::read_stderr($pid, "block" => 1);
my $t5 = Time::HiRes::time() - $t0;
my $t54 = $t5 - $t4;
okl($t54 <= 1.30, 
   "blocking read on empty stderr fast ${t54}s, expected <1.0s");
ok(!defined($err), "blocking read on empty stderr returns empty");

# print "\$err = $err, time = $t5, $t54\n";

$out = Forks::Super::read_stdout($pid, "block" => 0);
my $t6 = Time::HiRes::time() - $t0;
my $t65 = $t6 - $t5;
ok(!defined($out), "non-blocking read on empty stdout returns empty");
okl($t65 <= 1.0,
    "non-blocking read on empty stdout fast ${t65}s, expected <1.0s");

# print "\$out = $out, time = $t6, $t65\n";


# read_stdXXX with timeout

$pid = fork {
    child_fh => "out,err,socket",
    sub => sub {
	print STDERR "foo\n";
	sleep 6;
	print STDOUT "bar\n";
	sleep 12;
	print STDOUT "baz\n";
	exit 0;
    }
};
my $x = $pid->read_stderr(timeout => 3);
okl($x, "read avail stderr with timeout");                        ### 15 ###
$x = $pid->read_stdout(timeout => 1);
ok(!$x, "read unavail stdout with timeout");

# failure point on openbsd (single cpu?)
$x = $pid->read_stdout(timeout => 9);				  ### 17 ###
ok($x, "read avail stdout with timeout");
$x = $pid->read_stdout(timeout => 1);				  ### 18 ###
ok(!$x, "read unavail stdout with timeout");

$x = $pid->read_stdout(block => 1);
ok($x, "read stdout with block");
$x = $pid->read_stderr();
okl(!$x, "read unavail stderr")                                   ### 20 ###
   or diag("read \"$x\", expected nothing");
