#!perl -wT
use strict;
use Test::More tests => 1;

use HTML::Rebase qw(rebase_css);
my $css = <<CSS;
h1 { background-image: url('https://localhost:5000/css/hero.jpg') }
h2 { background-image: url('/css/hero.jpg') }
h3 { background-image: url('https://google.com/other.jpg') }
CSS

my $local_css = rebase_css( "https://localhost:5000/foo/test.html", $css );

my $expected = <<CSS;
h1 { background-image: url('../css/hero.jpg') }
h2 { background-image: url('../css/hero.jpg') }
h3 { background-image: url('https://google.com/other.jpg') }
CSS

s/\r?\n/ /g
    for ($local_css, $expected);

is $local_css, $expected, "Conversion matches";