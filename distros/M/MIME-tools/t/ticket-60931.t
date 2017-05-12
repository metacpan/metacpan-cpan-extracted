#!/usr/bin/perl
use Test::More tests => 2;
use MIME::Parser;

# RT#60931: Printing of empty preamble added extra newline before first boundary

my $original = do { local $/; <DATA> };
close(DATA);

my $generated = '';
my $fh = IO::File->new( \$generated, ">:" );

my $parser = MIME::Parser->new();
$parser->output_to_core(1);
my $entity = $parser->parse_data($original);
isa_ok( $entity, 'MIME::Entity');

$entity->print($fh);
$fh->close;
is( $original, $generated, 'Message with empty preamble roundtrips back to original');

__DATA__
MIME-Version: 1.0
Received: by 10.220.78.157 with HTTP; Thu, 26 Aug 2010 21:33:17 -0700 (PDT)
Content-Type: multipart/alternative; boundary=90e6ba4fc6ea25d329048ec69d99

--90e6ba4fc6ea25d329048ec69d99
Content-Type: text/plain; charset=ISO-8859-1

HELLO

--90e6ba4fc6ea25d329048ec69d99
Content-Type: text/html; charset=ISO-8859-1

HELLO<br>

--90e6ba4fc6ea25d329048ec69d99--
