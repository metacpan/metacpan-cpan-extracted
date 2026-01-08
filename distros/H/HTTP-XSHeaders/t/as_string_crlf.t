use strict;
use warnings;

use Test::More 'tests' => 2;
use HTTP::XSHeaders;

my $h = HTTP::XSHeaders->new(a => "foo\r\n\r\nbar");
is($h->as_string, "A: foo\r\n bar\n", "CRLF collapsed and folded with default eol");
is($h->as_string("\r\n"), "A: foo\r\n bar\r\n", "CRLF collapsed and folded with custom eol");
