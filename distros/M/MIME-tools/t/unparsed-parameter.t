use strict;
use warnings;
use Test::More tests => 9;

use MIME::Parser;

my $parser = MIME::Parser->new();
$parser->output_to_core(1);

my $msg = "Content-Type: multipart/mixed; x:y=1; boundary=A\n\n--A\n"
        . "Content-Type: text/plain\n\nhello\n--A--\n";
ok($parser->parse_data($msg)->ambiguous_content(),
   'Invalid parameter before boundary is ambiguous');

my $att = "Content-Type: text/plain\n"
        . "Content-Disposition: attachment; x:y=1; filename=a.exe\n\nhello\n";
ok($parser->parse_data($att)->ambiguous_content(),
   'Invalid parameter before filename is ambiguous');

my $semi = $msg;
$semi =~ s/x:y=1; boundary=A/x;boundary="B"; boundary=A/;
ok($parser->parse_data($semi)->ambiguous_content(),
   'Valueless parameter directly before boundary is ambiguous');

my $enc = $msg;
$enc =~ s/x:y=1; boundary=A/x==?; boundary=B; y?Q?z?=; boundary=A/;
ok($parser->parse_data($enc)->ambiguous_content(),
   'Encoded-word value spanning ";" is ambiguous');

my $quote = $msg;
$quote =~ s/x:y=1; boundary=A/a=x"; boundary=A; b="; boundary=B; c=""/;
ok($parser->parse_data($quote)->ambiguous_content(),
   'Stray quote between parameters is ambiguous');

my $type = $msg;
$type =~ s/mixed; x:y=1; boundary=A/mixed"; boundary=A; x="; boundary=B; y="/;
ok($parser->parse_data($type)->ambiguous_content(),
   'Stray quote in the type is ambiguous');

my $bs = $msg;
$bs =~ s/x:y=1; boundary=A/x="a\\\\"; boundary=A; y="; boundary=B; z="/;
ok($parser->parse_data($bs)->ambiguous_content(),
   'Quoted value ending in a backslash is ambiguous');

my $tail = "Content-Type: text/plain; charset=us-ascii; delsp\n\nhello\n";
ok(!$parser->parse_data($tail)->ambiguous_content(),
   'Trailing valueless parameter is not ambiguous');

$msg =~ s/x:y=1/charset=us-ascii/;
ok(!$parser->parse_data($msg)->ambiguous_content(),
   'Valid parameter before boundary is not ambiguous');
