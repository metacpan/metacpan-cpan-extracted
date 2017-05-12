use strict;
use warnings;

use File::Spec;

use HTML::Parser::Simple;

use Test::More tests => 1;

# -----------------------------------

my($p) = HTML::Parser::Simple -> new
(
	input_file  => File::Spec -> catfile('t', 'data', '90.xml.declaration.xhtml'),
	xhtml       => 1,
);

open(my $fh, '<', $p -> input_file) || BAILOUT("Can't read t/data/90.xml.declaration.xhtml");
my($html);
read($fh, $html, -s $fh);
close $fh;

my(@got)      = split(/\n/, $p -> parse($html) -> traverse($p -> root) -> result);
my($expected) = <<EOS;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Virtual Library</title>
  </head>
  <body>
    <p>Moved to <a href="http://example.org/">example.org</a>.</p>
  </body>
</html>
EOS

my(@expected) = split(/\n/, $expected);

is_deeply(\@got, \@expected, 'Got expected output of HTML::Parser::Simple.parse($xhtml)');