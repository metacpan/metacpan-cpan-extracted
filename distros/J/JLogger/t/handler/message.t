#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

use AnyEvent::XMPP::Parser;

use_ok 'JLogger::Handler::Message';

my $handler = new_ok 'JLogger::Handler::Message';

my $parser = AnyEvent::XMPP::Parser->new;

my $message;

$parser->set_stanza_cb(
    sub { $message = $handler->handle($_[1]) if defined $_[1]; });

$parser->feed(<<'XML');
<?xml version='1.0'?>
<stream:stream
    xmlns:stream='http://etherx.jabber.org/streams'
    xmlns='jabber:component:accept'
    from=''
    id='1'>
XML

$parser->feed(<<'XML');
<message
    from='sender@domain.com/resource'
    to='receiver@domain.com/resource'
    type='chat'
    id='id1'>
  <thread>thread1</thread>
  <body>body text</body>
</message>
XML

is $message->{to},   'receiver@domain.com/resource', 'message receiver';
is $message->{from}, 'sender@domain.com/resource',   'message sender';
is $message->{type}, 'message',                      'message type';

is $message->{message_type}, 'chat',      'message message_type';
is $message->{id},           'id1',       'message id';
is $message->{body},         'body text', 'message body';
is $message->{thread},       'thread1',   'message thread';

$parser->feed(<<'XML');
<message
    from='sender@domain.com'
    to='receiver@domain.com'>
  <composing xmlns='http://jabber.org/protocol/chatstates'/>
</message>
XML

is $message, undef, 'empty message';
