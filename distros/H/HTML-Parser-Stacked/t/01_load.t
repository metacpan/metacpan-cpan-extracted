use strict;
use Test::More;

my @modules = qw(HTML::Parser::Stacked);
plan(tests => scalar @modules);
use_ok($_) for @modules;