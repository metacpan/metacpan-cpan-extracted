#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok 'JLogger::Filter::Duplicate';

my $filter = new_ok 'JLogger::Filter::Duplicate';

my $message = {
    'to'           => 'rec@server.com/resource1',
    'from'         => 'sender@server.com',
    'type'         => 'message',
    'id'           => 1,
    'message_type' => 'chat',
    'body'         => 'body text',
};

ok !$filter->filter($message);

$message->{to} = 'rec@server.com/resource2';
ok $filter->filter($message);

$message->{id}++;

ok !$filter->filter($message);
