#!/usr/bin/perl -w

use Test::More;
use Mail::Exchange::Message;
use Mail::Exchange::Message::Email;
use Mail::Exchange::PidTagIDs;
use strict;
use diagnostics;

plan tests => 5;

ok(1, "Load Module");

my $message;

$message=Mail::Exchange::Message->new;
isa_ok($message, "Mail::Exchange::Message", "Create Message");

# same object type but message class property set
$message=Mail::Exchange::Message::Email->new;
isa_ok($message, "Mail::Exchange::Message", "Create Email object");
is($message->get(PidTagMessageClass), "IPM.Note", "Message Class set");

$message->setSubject("testsubject");
is($message->get(PidTagSubject), "testsubject", "String Property");
