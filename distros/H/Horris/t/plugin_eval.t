#!/usr/bin/env perl
use strict;
use warnings;
use lib ('lib', 't/lib');
use Horris::Instance;
use Horris::Connection;
use Horris::Connection::Plugin::Eval;
use Test::MockObject::Extends;
use Test::More (tests => 2);

my $plugin_name = 'Eval';
my $horris = Horris::Instance->new([$plugin_name]);
my $plugin = Horris::Connection::Plugin::Eval->new({
    parent => $horris->{conn}, 
    name => $plugin_name, 
});

my $conn = Test::MockObject::Extends->new('Horris::Connection');
$plugin->_connection($conn);

my $event = 'irc_privmsg';

my %test_message = (
    'eval: print 1 .. 10;' => '12345678910',    # general
    'eval print "나는미남";' => '나는미남'     # unicode
);

for my $key (keys %test_message) {
    $conn->mock($event, sub {
        my ($self, $args) = @_;
        like($args->{message}, qr/$test_message{$key}/);
    });

    my $message = Horris::Message->new(
        channel => '#test',
        message => $key, 
        from	=> 'test',
    );

    $plugin->$event($message);
}
