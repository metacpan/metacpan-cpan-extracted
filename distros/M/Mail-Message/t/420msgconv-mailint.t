#!/usr/bin/env perl
#
# Test conversions between Mail::Internet and Mail::Message
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Convert::MailInternet;

use Test::More;

BEGIN {
    eval {require Mail::Internet};
    if($@)
    {   warn "requires Mail::Internet.\n";
        plan tests => 0;
        exit 0;
    }

    plan tests => 21;
}


my $mi = Mail::Internet->new(\*DATA);
ok($mi);

my $convert = Mail::Message::Convert::MailInternet->new;
ok($convert);

#
# Convert Mail::Internet to Mail::Message
#

my $msg = $convert->from($mi);
ok($msg);

my $head = $msg->head;
ok($head);

my @fields = sort $head->names;
cmp_ok(@fields, "==", 5);
is($fields[0], 'again');
is($fields[1], 'from');
is($fields[2], 'in-reply-to');
is($fields[3], 'subject');
is($fields[4], 'to');

my @from  = $head->get('from');
cmp_ok(@from, "==", 1);

my @again = $head->get('again');
cmp_ok(@again, "==", 3);

my $body  = $msg->body;
ok($body);
my @lines = $body->lines;
cmp_ok(@lines, "==", 6);
is($lines[-1], "that.\n");

#
# Convert message back to a Mail::Internet
#

my $back = $convert->export($msg);
ok($back);
$head    = $back->head;

@fields  = $head->tags;
cmp_ok(@fields, "==", 5);
is($head->get('to'), "the users\n");

@from    = $head->get('from');
cmp_ok(@from, "==", 1);

@again   = $head->get('again');
cmp_ok(@again, "==", 3);

$body = $back->body;
cmp_ok(@$body, "==", 6);

1;

__DATA__
From: mailtools@overmeer.net
To: the users
Subject: use Mail::Box
In-Reply-To: <023984hjlur29420@sruoiu.nl>
Again: repeating header
Again: repeating header again
Again: repeating header and again

Mail::Internet was conceived in 1995, or even earlier, and
written by Graham Barr.  At that time, e-mail was not very
wide-spread (the beginning of WWW) and e-mails where not
poluted by graphics.  Attachments were even so rare that
Mail::Internet cannot handle them: see MIME::Entity for
that.
