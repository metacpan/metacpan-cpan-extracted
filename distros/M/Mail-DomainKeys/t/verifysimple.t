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
#is($mess->signature->domain, "foo");

$mess->signature->public($pubk);
ok($mess->verify, "verified the message!");

__DATA__
DomainKey-Signature: a=rsa-sha1; q=dns; c=simple;
  s=brisbane; d=football.example.com;
 b=P3MuhkRP01kGAVKS4wS9Y1d0zt7ptFpff0kajOrxhUTBOJSzflR5PIBV4P6Gklus
 OhFx8kp16vr6jTARPHsf+8YRqLta6WA5taSLvgnDEPDU0MdzZTCa1oX/Hw+Si6Zs
From: "Joe SixPack" <joe@football.example.com>
To: "Suzie Q" <suzie@shopping.example.net>
Subject: Is dinner ready?
Date: Fri, 11 Jul 2003 21:00:37 -0700 (PDT)
Message-ID: <20030712040037.46341.5F8J@football.example.com>

Hi.

We lost the game. Are you hungry yet?

Joe.







