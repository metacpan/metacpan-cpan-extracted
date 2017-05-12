#!/usr/bin/env perl
# Test conversions between Mail::Message and Email::Simple
#
# The tests are stolen from the MIME::Entity test-script, which
# makes the content bogus.

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;

use Test::More;

BEGIN
{   eval {require Email::Simple};
    if($@)
    {   plan skip_all => "requires Email::Simple.";
        exit 0;
    }

    require Mail::Message::Convert::EmailSimple;
    plan tests => 15;
}

my $email = Email::Simple->new(<<'END_MESSAGE');
From: mailtools@overmeer.net
To: the users
Subject: use Mail::Box
In-Reply-To: <023984hjlur29420@sruoiu.nl>
X-Again: repeating header
X-Again: repeating header again
X-Again: repeating header and again

MIME::Entity is written by Eriq, and extends Mail::Internet with many
new capabilities, like multipart bodies.  Actually, although it says
to extend, it more or less reimplements most methods and conflicts
with the other.  Even the Mail::Internet constructor does not work:
only the build() can be used to safely construct a message.  Do not
use it anymore!
END_MESSAGE

isa_ok($email, 'Email::Simple');

my $convert = Mail::Message::Convert::EmailSimple->new;
ok($convert);

#
# Convert Email::Simple to Mail::Message
#

my $msg = $convert->from($email);
ok($msg);

my $head = $msg->head;
ok($head);

my @from  = $head->get('From');
cmp_ok(@from, "==", 1);

my @again = $head->get('X-again');
is(@again, 3);

my $body  = $msg->body;
ok($body);
my @lines = $body->lines;
cmp_ok(@lines, "==", 6);
is($lines[-1], "use it anymore!\n");

#
# Convert message back to an Email::Simple
#

my $back = $convert->export($msg);
ok(defined $back);

is($back->header('to'), "the users");

@from    = $back->header('from');
cmp_ok(@from, "==", 1);

@again   = $back->header('x-again');
cmp_ok(@again, "==", 3);

$body = $back->body;
ok($body);

@lines = split /\n/, $body;
cmp_ok(@lines, "==", 6);
