use v5.40;
use Test2::V1 -ipP;
use Gears::Logger;

################################################################################
# This tests whether the basic logger works
################################################################################

package Gears::Test::Logger {
	use Mooish::Base -standard;

	extends 'Gears::Logger';

	has param 'log_dest' => (
		isa => ArrayRef,
	);

	sub _log_message ($self, $level, $message)
	{
		push $self->log_dest->@*, [$level, $message];
	}
}

subtest 'should output string messages' => sub {
	my @logs;
	my $logger = Gears::Test::Logger->new(log_dest => \@logs);

	$logger->message(error => 'custom test');
	is scalar @logs, 1, 'message logged';
	is $logs[0][0], 'error', 'level ok';
	like $logs[0][1], qr{^\[.+\] \[ERROR\] custom test$}, 'message ok';
};

subtest 'should output multiple messages' => sub {
	my @logs;
	my $logger = Gears::Test::Logger->new(log_dest => \@logs);

	$logger->message(error => 'msg1', 'msg2');
	is scalar @logs, 2, 'message logged';

	is $logs[0][0], 'error', 'level ok';
	like $logs[0][1], qr{^\[.+\] \[ERROR\] msg1$}, 'message ok';

	is $logs[1][0], 'error', 'level ok';
	like $logs[1][1], qr{^\[.+\] \[ERROR\] msg2$}, 'message ok';
};

subtest 'should output ref messages' => sub {
	my @logs;
	my $logger = Gears::Test::Logger->new(log_dest => \@logs);

	$logger->message(info => ['test1', 'test2']);
	is scalar @logs, 1, 'message logged';
	is $logs[0][0], 'info', 'level ok';
	like $logs[0][1], qr{^\[.+\] \[INFO\] \$VAR1 = \[\v\s*'test1'}, 'message ok';
};

subtest 'should not output a single trailing newline' => sub {
	my @logs;
	my $logger = Gears::Test::Logger->new(log_dest => \@logs);

	$logger->message(info => "test\n");
	is scalar @logs, 1, 'message logged';
	is $logs[0][0], 'info', 'level ok';
	like $logs[0][1], qr{^\[.+\] \[INFO\] test$}, 'message ok';
};

done_testing;

