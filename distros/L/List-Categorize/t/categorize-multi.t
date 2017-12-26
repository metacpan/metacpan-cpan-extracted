#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;

use List::Categorize qw( categorize );

my @list = qw( apple banana antelope bear canteloupe coyote ananas );

#----------------------------------------------------------------------
# subcategories with 1-letter and 2-letter prefixes (and modified elements)
my %sublists = categorize {
  $_ = ucfirst $_;

  # Use the first letter of the element as the category,
  # then the first 2 letters as a second-level category
  substr($_, 0, 1), substr($_, 0, 2);
} @list;

my %expected = (
  A => { An => ['Antelope', 'Ananas'], Ap => ['Apple'], },
  B => { Ba => ['Banana'],             Be => ['Bear'],  },
  C => { Ca => ['Canteloupe'],         Co => ['Coyote'] },
 );

is_deeply(\%sublists, \%expected, 'Multilevel categories');

#----------------------------------------------------------------------
# inconsistent categories (used both as node and as leaf)
eval { categorize  { /(a)/g } @list };
like ($@, qr/inconsistent use/, "inconsistent categories");

#----------------------------------------------------------------------
# empty categories
my %empty = categorize  { } @list;
ok (! keys %empty, "empty result");

#----------------------------------------------------------------------
# undef elimination
%sublists = categorize  {no warnings 'substr';
                         (substr($_, 0, 1), substr($_, 5,1) || undef)} @list;
%expected = (
  a => { o => ['antelope'], s => ['ananas']},
  b => { a => ['banana']},
  c => { e => ['coyote'],   l => ['canteloupe']},
 );
is_deeply(\%sublists, \%expected, "undef elimination");
