#!/usr/bin/perl

use strict;
use warnings;

use Lingua::TreeTagger::Filter;


use Test::More tests => 2;


################################################################################
#TEST Hit
################################################################################

my $hit = Lingua::TreeTagger::Filter::Result::Hit->new(
  'begin_index'     => 1,
  'sequence_length' => 1,
);

isa_ok( $hit, 'Lingua::TreeTagger::Filter::Result::Hit', "test Hit: simple case");

ok (
  $hit->get_begin_index() == 1 && $hit->get_sequence_length() == 1,
  "test Hit, simple case (values)",
);