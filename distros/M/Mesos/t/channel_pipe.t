#!/usr/bin/perl
use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Mesos::Channel::Pipe;

my $channel = Mesos::Channel::Pipe->new;
like($channel->fd, qr/^\d+$/, 'channel fd returned int');

is($channel->recv, undef, 'returned undef on empty recv');

my $sent_command = "test command";
my @sent_args = (qw(some test args), [qw(and an array ref)]);
$channel->send($sent_command, @sent_args);
my ($command, @args) = $channel->recv;
is($command, $sent_command, 'received sent command');
is_deeply(\@args, \@sent_args, 'received sent args');

use Mesos::Messages;
my $single = Mesos::FrameworkID->new({value => 'single'});
my $array = [Mesos::FrameworkID->new({value => 'an'}), Mesos::FrameworkID->new({value => 'array'})];
my @message_args = ('test messages', $single, $array);
$channel->send(@message_args);
is_deeply([$channel->recv], \@message_args, 'received mesos messages');

is($channel->recv, undef, 'cleared queue');
done_testing;
