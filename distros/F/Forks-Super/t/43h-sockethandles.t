use Forks::Super qw(:test overload);
use Forks::Super::Util qw(is_socket);
use Test::More tests => 14;
use strict;
use warnings;

$Forks::Super::SOCKET_READ_TIMEOUT = 0.25;

# test blocked and unblocked reading for socket handles.

my $pid = fork {
    child_fh => "out,err,socket,block",
    sub => sub {
	print STDERR "foo\n";
	sleep 5;
	print STDOUT "bar\n";
	sleep 5;
	print STDOUT "baz\n";
    }
};

ok(isValidPid($pid), "$pid is valid pid");
ok(is_socket($pid->{child_stdout}), "ipc with sockets");
sleep 1;
my $t0 = Time::HiRes::time();
my $err = Forks::Super::read_stderr($pid);
my $t1 = Time::HiRes::time() - $t0;
ok($err =~ /^foo/, "read stderr");
okl($t1 <= 1.0, "read blocked stderr fast ${t1}s, expected <1s");

my $out = Forks::Super::read_stdout($pid);
my $t2 = Time::HiRes::time() - $t0;
ok($out =~ /^bar/, "read stdout");
okl($t2 > 2.95, "read blocked stdout ${t2}s, expected ~4s");

$out = Forks::Super::read_stdout($pid, "block" => 0);
my $t3 = Time::HiRes::time() - $t0;
my $t32 = $t3 - $t2;
ok(!defined($out), "non-blocking read on stdout returned empty");
okl($t32 <= 1.0, "non-blocking read took ${t32}s, "
                 . "expected ~${Forks::Super::SOCKET_READ_TIMEOUT}s");

$out = Forks::Super::read_stdout($pid);
my $t4 = Time::HiRes::time() - $t0;
my $t43 = $t4 - $t3;
ok($out =~ /^baz/, "successful blocking read on stdout");
okl($t43 > 3.5, "read blocked stdout ${t43}s, expected ~5s");

#### no more input on STDOUT or STDERR

$err = Forks::Super::read_stderr($pid);
my $t5 = Time::HiRes::time() - $t0;
my $t54 = $t5 - $t4;
ok(!defined($err), "blocking read on empty stderr returns empty");
okl($t54 <= 1.30, 
   "blocking read on empty stderr fast ${t54}s, expected <1.0s");

# print "\$err = $err, time = $t5, $t54\n";

$out = Forks::Super::read_stdout($pid, "block" => 0);
my $t6 = Time::HiRes::time() - $t0;
my $t65 = $t6 - $t5;
ok(!defined($out), "non-blocking read on empty stdout returns empty");
okl($t65 <= 1.0,
    "non-blocking read on empty stdout fast ${t65}s, expected <1.0s");

# print "\$out = $out, time = $t6, $t65\n";


