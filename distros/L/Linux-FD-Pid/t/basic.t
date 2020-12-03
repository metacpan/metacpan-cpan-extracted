#! perl

use strict;
use warnings;

use Test::More;

use POSIX 'SIGUSR1';
use IO::Select;
use Linux::FD::Pid;

for my $status (0, 2, 255) {
	my $pid = fork;
	die if not defined $pid;

	if ($pid) {
		my $select = IO::Select->new;
		my $pidfd = Linux::FD::Pid->new($pid);
		$select->add($pidfd);
		ok $select->can_read(1);
	}
	else {
		exit $status;
	}
}


pipe my($in), my($out);
$SIG{USR1} = sub { syswrite $out, "$_[0]" };
my $outfd = fileno $out;

my $pid = fork;
die if not defined $pid;
if ($pid) {
	close $out;
	my $pidfd = Linux::FD::Pid->new($pid);
	$pidfd->send(SIGUSR1);
	read $in, my $buffer, 4 or die;
	is($buffer, 'USR1');
	my $out_clone = $pidfd->get_handle($outfd);
	alarm 2;
	is($pidfd->wait, 42, 'Pid returns 42');
	syswrite $out_clone, 'Bar' or die;
	read $in, $buffer, 3 or die;
	is($buffer, "Bar");
}
else {
	sleep 1;
	exit 42;
}
done_testing;
