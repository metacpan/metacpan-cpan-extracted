#!perl
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('HTML::AsText::Fix');
}

diag("Testing HTML::AsText::Fix v$HTML::AsText::Fix::VERSION, HTML::Tree v$HTML::Tree::VERSION, Perl $], $^X");
