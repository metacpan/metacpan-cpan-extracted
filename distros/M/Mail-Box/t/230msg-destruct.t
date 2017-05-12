#!/usr/bin/env perl
#
# Test destruction of (folder) messages
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;

use Test::More tests => 58;


my @src = (folder => "=$fn", folderdir => $folderdir);

#
# Destruct folder messages
#

my $folder = Mail::Box::Mbox->new
  ( @src
  , lock_type    => 'NONE'
  );

ok(defined $folder,                   'check success open folder');
exit 1 unless defined $folder;

my ($delayed, $read) = (0,0);
foreach my $msg ($folder->messages)
{  $msg->isDelayed ? $delayed++ : $read++;
}

ok($delayed,                          'some messages are delayed');
ok($read,                             'some messages are fully read');

foreach my $msg ($folder->messages)
{  $msg->destruct;
   isa_ok($msg, 'Mail::Box::Message::Destructed', "msg ".$msg->seqnr);
}

isa_ok($folder->message(0), 'Mail::Box::Message::Destructed', 'first');

# some things still work
my $msg0 = $folder->message(0);
ok(!$msg0->isDeleted,  'destructed is not deleted');
ok($msg0->delete,      'delete is allowed');
ok($msg0->messageId, 'has message id');

$folder->close(write => 'NEVER');

#
# Destruct Mail::Message
#

my $msg = Mail::Message->read( <<MSG );
Subject: hi!

body
MSG

ok(defined $msg,                 'constructed a Mail::Message');
is($msg->get('Subject'), "hi!",  'check headers read');
is($msg->body->string, "body\n", 'check body read');
my $alias = $msg;

$msg->destruct;
ok(!defined $msg,                'destruct removes link');
ok(defined $alias->body,         'body still exists');
$alias->destruct;
ok(!defined $alias,              'destruct removes link');
