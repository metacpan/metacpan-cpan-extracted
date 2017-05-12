#!perl -wT
use strict;
use Test::More tests => 1;

use HTML::Rebase qw(rebase_html rebase_css);
my $html = <<HTML;
  <html>
  <head>
  <link rel="stylesheet" src="http://localhost:5000/css/site.css" />
  </head>
  <body>
  <a href="http://perlmonks.org">Go to Perlmonks.org</a>
  <a href="http://localhost:5000/index.html">Go to home page/a>
  </body>
  </html>
HTML

my $local_html = rebase_html( "http://localhost:5000/about.html", $html );

my $expected = <<HTML;
  <html>
  <head>
  <link rel="stylesheet" src="css/site.css" />
  </head>
  <body>
  <a href="http://perlmonks.org">Go to Perlmonks.org</a>
  <a href="index.html">Go to home page/a>
  </body>
  </html>
HTML

s/\r?\n/ /g
    for ($local_html, $expected);

is $local_html, $expected, "Conversion matches";