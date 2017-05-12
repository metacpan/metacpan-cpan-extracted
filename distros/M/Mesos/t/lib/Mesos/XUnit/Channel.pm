package Mesos::XUnit::Channel;
use Mesos::Channel;
use Mesos::Messages;
use Test::LeakTrace;
use Test::Class::Moose;

sub new_channel { Mesos::Channel->new }

sub test_empty_recv { 
    my ($test) = @_;
    is($test->new_channel->recv, undef, 'returned undef on empty recv');
}

sub test_plain_data {
    my ($test)  = @_;
    my $channel = $test->new_channel;

    my $sent_command = "test command";
    my @sent_args = (qw(some test args), [qw(and an array ref)]);
    $channel->send($sent_command, @sent_args);

    my ($command, @args) = $channel->recv;
    is($command, $sent_command, 'received sent command');
    is_deeply(\@args, \@sent_args, 'received sent args');
}

sub test_mesos_messages {
    my ($test) = @_;
    my $channel = $test->new_channel;

    my $single = Mesos::FrameworkID->new({value => 'single'});
    my $array = [Mesos::FrameworkID->new({value => 'an'}), Mesos::FrameworkID->new({value => 'array'})];
    my @message_args = ('test messages', $single, $array);
    $channel->send(@message_args);

    is_deeply([$channel->recv], \@message_args, 'received mesos messages');
    is($channel->recv, undef, 'cleared queue');
}

sub test_constructor_leaks {
    my ($test) = @_;

    # this leaks under some setups unless Mesos::Channel has already been loaded
    $test->new_channel;
    no_leaks_ok {
        $test->new_channel;
    } 'Mesos::Channel construction does not leak';
}

sub test_data_sending_leaks {
    my ($test) = @_;

    no_leaks_ok {
        my $channel = $test->new_channel;
        my $sent_command = "test command";
        my @sent_args = (
            'string',
            [qw(array of strings)],
            Mesos::FrameworkID->new({value => 'single'}),
            [Mesos::FrameworkID->new({value => 'an'}), Mesos::FrameworkID->new({value => 'array'})]
        );
        $channel->send($sent_command, @sent_args);
        $channel->recv;
    } 'Mesos::Channel sent data without leak';
}

1;
