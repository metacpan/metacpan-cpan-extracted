use Test::More tests => 3;
# $Id: classic.t,v 1.1 2006/01/17 22:11:38 cwest Exp $
use strict;
$^W =1;

BEGIN {
  use_ok 'Email::Send';
}

use Email::Send;
use lib 't/lib';

my $message = <<'.';
From: rjbs@foo.bar
To: rjbs@baz.boo
Subject: test message
Date: Thu, 2 Feb 2006 21:51:53 -0500

This is a test, a what, a test, a what, a test, oh, a test!
.

my $sender = Email::Send->new({ mailer => 'OKMailer' });

my $rv = $sender->send($message);

ok($rv, "message sending returned success");

