use Test::More tests => 7;
use Mail::DomainKeys::Message;
use Mail::DomainKeys::Key::Public;

use strict;

my $pubk = new Mail::DomainKeys::Key::Public;

ok(defined $pubk, "made the key...");
isa_ok($pubk, "Mail::DomainKeys::Key::Public");

$pubk->data(
	"MHwwDQYJKoZIhvcNAQEBBQADawAwaAJhAKJ2lzDLZ8XlVambQfMXn3LRGKOD5o6l" .
	"MIgulclWjZwP56LRqdg5ZX15bhc/GsvW8xW/R5Sh1NnkJNyL/cqY1a+GzzL47t7E" .
	"XzVc+nRLWT1kwTvFNGIoAUsFUq+J6+OprwIDAQAB");

is($pubk->type, "rsa", "and the correct type... ");

is($pubk->cork->size, 96, "and the correct size!");

my $mess = load Mail::DomainKeys::Message(File => \*::DATA);

ok(defined $mess, "loaded the message...");
isa_ok($mess, "Mail::DomainKeys::Message");

$mess->signature->public($pubk);
ok($mess->verify, "verified the message!");

__DATA__
DomainKey-Signature: a=rsa-sha1; q=dns; c=nofws;
  s=brisbane; d=football.example.com;
 b=huRfZdcsFJ/XwIIQpzF44yRDLY2ZzA8TCAQm0BClTZzzpprme3Ebprt6Uzz5RQpk
 HYXyydu62R2gD2QtislCw9aG9VpoEpKgIRLzNfXv5mfdwA4OfyYjFxPTA8hOkQco
From: "Joe SixPack" <joe@football.example.com>
To: "Suzie Q" <suzie@shopping.example.net>
Subject: Is dinner ready?
Date: Fri, 11 Jul 2003 21:00:37 -0700 (PDT)
Message-ID: <20030712040037.46341.5F8J@football.example.com>

Hi.

Welost the game.  Are you hungry yet?

Joe.







