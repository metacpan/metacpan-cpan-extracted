#!/usr/bin/perl -w
#
# Recipe copy ranges are JSON integers (spec-06 §5 schema: "c" items are
# {"type": "integer", "minimum": 1}).
#
# Regression: the header-recipe builder used each range index as a hash key
# while de-duplicating copies, which stringifies the scalar in place, so the
# JSON encoder emitted {"c":["2","2"]}.  Our own parser and the C and JS
# verifiers took the strings; Go rejected every such Message-Instance as
# invalid JSON.  Found 2026-10-04 replaying real mail through the Sympa test
# list (util/charset-corpus.sh) -- every Sympa m=2 carried string ranges.

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use MIME::Base64 qw(decode_base64);
use lib 'lib';

use Mail::DKIM2::MessageInstance;

my $previous = Email::MIME->new(join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: list\@test2.dkim2.com\r\n",
    "Subject: ranges\r\n",
    "Comments: one\r\n",
    "Comments: two\r\n",
    "Precedence: list\r\n",
    "Message-ID: <ranges\@test1.dkim2.com>\r\n",
    "Content-Type: text/plain\r\n",
    "\r\n",
    "line 1\r\n",
    "line 2\r\n",
    "line 3\r\n",
));

# A list hop: keeps one Comments (so the recipe copies it by index and
# restores the other literally), moves Precedence, appends a footer (so the
# body recipe is a copy range too).
my $current = Email::MIME->new(join('',
    "Precedence: list\r\n",
    "From: sender\@test1.dkim2.com\r\n",
    "To: list\@test2.dkim2.com\r\n",
    "Subject: ranges\r\n",
    "Comments: two\r\n",
    "Message-ID: <ranges\@test1.dkim2.com>\r\n",
    "Content-Type: text/plain\r\n",
    "List-Id: <list.test2.dkim2.com>\r\n",
    "\r\n",
    "line 1\r\n",
    "line 2\r\n",
    "line 3\r\n",
    "-- \r\n",
    "footer\r\n",
));

# calculate() needs the previous hop's instance on both messages, as it
# would be in real mail.
my $mi1 = Mail::DKIM2::MessageInstance->calculate($previous);
$_->header_raw_prepend('Message-Instance', $mi1->as_string) for $previous, $current;

my $mi = Mail::DKIM2::MessageInstance->calculate($current, $previous);
my $text = $mi->as_string;
my ($r) = $text =~ /\br=([A-Za-z0-9+\/=\s]+)/ or BAIL_OUT("no r= in: $text");
$r =~ s/\s+//g;
my $json = decode_base64($r);
note $json;

like($json, qr/"c":\[\d+,\d+\]/, 'at least one copy range is emitted');
unlike($json, qr/"c":\["/, 'no copy range index is a JSON string');
like($json, qr/"comments":\[\{"c":\[1,1\]\},\{"d":\["one"\]\}\]/,
    'header copy range for the kept Comments is integer [1,1]');
like($json, qr/"b":\[\{"c":\[1,3\]\}\]/, 'body copy range is integer [1,3]');

# And round-trip: our own parser still reads them (it accepted strings too,
# so this guards the fix from breaking the parse side).
my $parsed = Mail::DKIM2::MessageInstance->parse($text);
is_deeply($parsed->get_tag('rb'), [[1, 3]], 'parsed body recipe is the numeric range');

done_testing;
