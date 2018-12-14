#!/usr/bin/perl
use Test::More tests => 1;
use File::Extension qw(explain);



is(
  (explain('NES')),
  "Nintendo (NES) ROM File",
  'explain() OK',
);
