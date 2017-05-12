#!perl -wT
use strict;
use Test::More tests => 2;

use HTML::Rebase qw(rebase_html rebase_css);

for my $case (
    ['<a href=http://localhost:5000/index.html >Go to home page</a>', '<a href="index.html" >Go to home page</a>','ends with blank'],
    ['<a href=http://localhost:5000/index.html>Go to home page</a>', '<a href="index.html">Go to home page</a>','ends with >'],
    ) {
      my ($html, $expected, $name) = @$case;
      my $local_html = rebase_html( "http://localhost:5000/about.html", $html );

      is $local_html, $expected, $name;
};
      