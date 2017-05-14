#!/usr/bin/env perl
use strict;
use warnings;
use lib ('lib', 't/lib');
use Horris::Instance;
use Horris::Connection;
use Horris::Connection::Plugin::PeekURL;
use Test::MockObject::Extends;
use Test::More (tests => 1);

my $plugin_name = 'PeekURL';
my $horris = Horris::Instance->new([$plugin_name]);
my $plugin = Horris::Connection::Plugin::PeekURL->new({
    parent => $horris->{conn}, 
    name => $plugin_name, 
});

my $conn = Test::MockObject::Extends->new('Horris::Connection');
$plugin->_connection($conn);

my $cv = AnyEvent->condvar;

my $event = 'irc_notice';
$conn->mock($event, sub {
    my ($self, $args) = @_;
    diag($args->{message});
    like($args->{message}, qr/팁과강좌/);
    $cv->send;
});

my $message = Horris::Message->new(
    channel => '#test',
    message => 'http://clien.career.co.kr/cs2/bbs/board.php?bo_table=lecture&wr_id=69558', 
    from	=> 'test'
);

$plugin->irc_privmsg($message);

my $w; $w = AnyEvent->timer(after => 5, cb => sub { undef $w; $cv->send });
$cv->recv;
