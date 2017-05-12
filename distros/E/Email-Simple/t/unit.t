#!/usr/bin/perl
# This is a series of unit tests to ensure that things do what I think
# they do.
use strict;
use Email::Simple;

package Email::Simple;
use Test::More tests => 8;

# Simple "email", no body

my $text = "a\nb\nc\n";
my ($pos, $crlf) = Email::Simple->_split_head_from_body(\$text);
is($pos, undef, "no body position!");
is($crlf, "\n", 'and \n is the crlf');

# Simple "email", properly formed

$text = "a\n\nb\n";
($pos, $crlf) = Email::Simple->_split_head_from_body(\$text);
is($pos, 3, "body starts at pos 3");
is($crlf, "\n", 'and \n is the crlf');

# Simple "email" with blank lines

$text = "a\n\nb\nc\n";
($pos, $crlf) = Email::Simple->_split_head_from_body(\$text);
is($pos, 3, "body starts at pos 3");
is($crlf, "\n", 'and \n is the crlf');

# Blank line as first line in email
$text = "a\n\n\nb\nc\n";
($pos, $crlf) = Email::Simple->_split_head_from_body(\$text);
is($pos, 3, "body starts at pos 3");
is($crlf, "\n", 'and \n is the crlf');
