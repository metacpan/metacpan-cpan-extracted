#! perl -d:cst

use strict;
use warnings FATAL => 'all';
no warnings 'recursion'; # Doing bad stuff on purpose

use Test::More 0.89;

use Config;
use POSIX qw/:sys_wait_h raise SIGSEGV/;

plan(skip_all => 'no fork') if not $Config{d_fork};

sub check_segv(&@);

my $raised = $^O eq 'darwin' ? qr/Signal with unknown cause or source/ : qr/Signal sent by kill\(\)(?: \[.*?\])?/;
my $address_not_mapped = qr/Address not mapped to object \[.*?\]/s;

check_segv { raise(SIGSEGV) } $raised, 'Got stacktrace on raise';
sub z { [ sort { z() } 1, 2 ] }
check_segv { z() } $address_not_mapped, 'sort recursion segfaults';
check_segv { unpack "p", pack "L!", 1; } $address_not_mapped, 'Acme::Boom trick';
check_segv { eval 'package Regexp; use overload q{""} => sub { qr/$_[0]/ }; "".qr//' } $address_not_mapped, "Got stacktrace on overload recursion" if $] < 5.017;
#check_segv { local @INC = sub { require $_[0] }; require ExtUtils::Embed } $address_not_mapped, 'Require stack overflows';

done_testing;

sub check_segv(&@) {
	my ($sub, $extra, $message) = @_;

	pipe my $in, my $out or die "Can't pipe: $!";
	my $pid = fork;
	die "Can't fork: $!" if not defined $pid;

	if ($pid) {
		close $out;
		my $status = waitpid -1, 0;
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		ok(WIFSIGNALED(${^CHILD_ERROR_NATIVE}), "Test died properly");
		my $output = <$in>;
		like $output, qr/Segmentation fault \($extra\)/i, $message;
		my @rest = <$in>;
		ok @rest, "Test \'$message\' gave a stacktrace";
	}
	else {
		alarm 2;
		open STDERR, '<&', fileno $out;
		$sub->();
		die "Threw no signal?\n";
	}
}

