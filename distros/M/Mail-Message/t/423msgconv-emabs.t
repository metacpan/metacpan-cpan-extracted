#!/usr/bin/env perl
#
# Test coercion from Email::Abstract to Mail::Message

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;

use Test::More;

BEGIN
{   eval { require Email::Abstract };
    if($@)
    {   plan skip_all => "requires Email::Abstract.";
        exit 0;
    }

    eval { require Email::Simple };
    if($@)
    {   plan skip_all => "requires Email::Simple.";
        exit 0;
    }

    plan tests => 6;
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

is($email->header('in-reply-to'), '<023984hjlur29420@sruoiu.nl>');

my $abstract = Email::Abstract->new($email);

isa_ok($abstract, 'Email::Abstract');

is($abstract->get_header('in-reply-to'), '<023984hjlur29420@sruoiu.nl>');

my $message = Mail::Message->coerce($abstract);

isa_ok($message, 'Mail::Message');

is($message->get('in-reply-to'), '<023984hjlur29420@sruoiu.nl>');
