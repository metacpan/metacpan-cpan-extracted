#!perl

use strict;
use warnings;
use Test::More tests => 7;

my @functions;
BEGIN {
    use_ok ('List::Search', @functions = qw(
        list_search   nlist_search   custom_list_search
        list_contains nlist_contains custom_list_contains
    )) or BAIL_OUT;
}
diag ("Testing List::Search $List::Search::VERSION, Perl $], $^X");

foreach (@functions) {
    no strict 'refs';
    ok (exists &{$_}, "&$_ is imported");
}
