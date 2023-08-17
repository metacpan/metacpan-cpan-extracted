#!/usr/bin/env perl
#
# Test the processing of a message header, in this case purely the reading
# from a file.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Message;
use Mail::Message::Head;
use Mail::Box::Parser::Perl;

use Test::More tests => 16;


my $h = Mail::Message::Head->new;
ok(defined $h);

my $parser = Mail::Box::Parser::Perl->new(filename => $src);
ok($parser);

my $head = Mail::Message::Head->new;
ok(defined $head);
ok(! $head);  # no lines yet

$parser->pushSeparator('From ');
my ($where, $sep) = $parser->readSeparator;
ok($sep);
cmp_ok($where, "==", 0);
like($sep , qr/^From mag.*2000$/);

$head->read($parser);
ok($head);  # now has lines
cmp_ok($head->names, "==", 20);
is($head->get('subject'), 'Re: File Conversion From HTML to PS and TIFF');

my @received = $head->get('received');
cmp_ok(@received, "==", 5);

my $received = $head->get('received');  #last
ok(defined $received);
is($received->name, 'received');
my $recb = "(from majordomo\@localhost)\tby unca-don.wizards.dupont.com (8.9.3/8.9.3) id PAA29389\tfor magick-outgoing";

is($received->body, $recb);
is($received->comment, 'Wed, 9 Feb 2000 15:38:42 -0500 (EST)');

# Check parsing empty fields
# Contributed by Marty Pauley

my $message = <<'EOT';
Date: Mon, 24 Feb 2003 11:07:36 +0000
From: marty@kasei.com
To: marty@kasei.com
Subject: Test Message
Message-ID: <20030224010736.GA32736@phobos.kasei.com>
Mime-Version: 1.0
X-foo:
Content-Type: text/plain
Content-Disposition: inline

This is a test message.
EOT
my $mm = Mail::Message->read($message);
my $foo = $mm->head->get("x-foo")->string;
is($foo, "X-foo: \n",               "X-foo ok");
