#!perl -w
use strict;
use Test::More tests => 13;
use_ok('Mariachi::Message');

my $m = Mariachi::Message->new(<<'MAIL');
From: Doc Brown <doc@inventors>
To: world
Message-Id: 1.21@dealers
Date: Sat, 12 November 1955 22:02:00
Subject: Time Travel

I have a hunch
MAIL

isa_ok( $m, 'Mariachi::Message' );

is( $m->header('from'), 'Doc Brown <doc@inventors>', "get the from header" );
is( $m->from,           'Doc Brown', "sanitised from" );
is( $m->date,           'Sat, 12 November 1955 22:02:00' );
is( $m->subject,        'Time Travel' );
is( $m->filename,       '1955/11/12/51cf7416.html' );
is( $m->body,           "I have a hunch\n" );
is( $m->body_sigless,   "I have a hunch\n" );
is( $m->sig,            undef);

my $m2 = Mariachi::Message->new(<<'MAIL');
From: x@y
Date: z

> no messageid

nor here

-- 
But we do have a sig
MAIL

is( $m2->header('message-id' ), '1d6e9e79@made_up', "faked a messageid" );
is( $m2->sig,             "But we do have a sig\n" );

# test for name extraction working properly, even with quotes in it

my $m3 = Mariachi::Message->new(<<'MAIL');
From: "Mark Fowler" <someonestupid@twoshortplanks.com>
Subject: Thingys not working

The things with the quote marks and the biting of teeth
MAIL
is( $m3->from, 'Mark Fowler', "double quote removal");
