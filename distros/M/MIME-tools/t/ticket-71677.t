#!/usr/bin/perl
use Test::More tests => 2;
use MIME::Parser;

my $msg = <<'EOF';
From: <devnull@example.com>
To: <devnull@example.com>
Subject: Weird filename test
MIME-Version: 1.0
Content-Type: application/octet-stream; name="[wookie].bin"
Content-Disposition: attachment; filename="[wookie].bin"

Wookie
EOF

my $parser = MIME::Parser->new();
$parser->output_to_core(0);
$parser->output_under("testout");
my $entity = $parser->parse_data($msg);
my $body = $entity->bodyhandle;
my $path = $body->path;
ok(defined($path), 'Path exists');
ok($path =~ /_wookie_\.bin$/, 'And has the expected form');

$parser->filer->purge;
