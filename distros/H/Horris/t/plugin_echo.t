#!/usr/bin/env perl
use strict;
use warnings;
use lib ('lib', 't/lib');
use Horris::Instance;
use Horris::Connection;
use Horris::Connection::Plugin::Echo;
use Test::MockObject::Extends;
use Test::More (tests => 2);

my $plugin_name = 'Echo';
my $horris = Horris::Instance->new([$plugin_name]);
my $plugin = Horris::Connection::Plugin::Echo->new({
    parent => $horris->{conn}, 
    name => $plugin_name, 
});

$plugin->enable;
my $conn = Test::MockObject::Extends->new('Horris::Connection');
$plugin->_connection($conn);

my $event = 'irc_privmsg';
my $from = 'test';

my %test_message = (
    'perl' => ': perl',             # general
    '안녕하세요' => ": 안녕하세요"  # unicode
);

$conn->mock('nickname', sub { 'hongbot' });

for my $key (keys %test_message) {
    $conn->mock($event, sub {
        my ($self, $args) = @_;
        like($args->{message}, qr/$test_message{$key}/);
    });

    my $message = Horris::Message->new(
        channel => '#test',
        message => $key, 
        from	=> $from
    );

    $plugin->$event($message);
}
