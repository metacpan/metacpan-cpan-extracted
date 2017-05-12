use Test::More tests => 1;

use MIME::Parser;

my $parser = MIME::Parser->new();
$parser->output_to_core(1);

my $message = <<'EOF';
From: <devnull@example.org>
To: <devnull@example.com>
Subject: Ticket #71041 test
Message-Id: <cheese@burger.org>
MIME-Version: 1.0
Content-Type: text/plain

This should parse properly.
EOF

# Set $\ to something wacky
$\ = "\n";

my $entity = $parser->parse_data($message);
my $head = $entity->head;
is ($head->get('From'), "<devnull\@example.org>\n", 'Header was parsed as expected');
