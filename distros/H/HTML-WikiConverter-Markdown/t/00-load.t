#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('HTML::WikiConverter::Markdown');
}

diag("Testing HTML::WikiConverter::Markdown $HTML::WikiConverter::Markdown::VERSION, Perl $], $^X");

