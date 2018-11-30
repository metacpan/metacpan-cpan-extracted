#!perl -wT
use strict;
use Test::More tests => 3;

use HTML::Rebase qw(rebase_html rebase_css);

for my $case (
    ['<base href="http://public.website"><a href="/bar/index.html">Go to home page</a>',
      '<a href="bar/index.html">Go to home page</a>',
      '<base> tag gets respected'
    ],
    ['<base href="http://localhost:5000/app"><a href="index.html">Go to app home page</a>', '<a href="index.html">Go to app home page</a>','<base> tag gets respected'],
    ['<bASE href="http://localhost:5000/app"><a href="index.html">Go to app home page</a>', '<a href="index.html">Go to app home page</a>','<bASE> tag gets respected'],
    ) {
      my ($html, $expected, $name) = @$case;
      my $local_html = rebase_html( "http://localhost:5000/about.html", $html );

      is $local_html, $expected, $name;
};
      