#!/usr/bin/perl

use strict;
use warnings;

use Lingua::TreeTagger::Filter;


use Test::Simple tests => 6;


################################################################################
#TEST ELEMENT
################################################################################
my $element = Lingua::TreeTagger::Filter::Element->new(
    'lemma'       => 'lemma1',
    'original'    => 'original1',
    'tag'         => 'tag1',
    'quantifier'  => 'quantifier1',
);

#test the creation of a Lingua::TreeTagger::Filter::Element
ok( $element->lemma() eq '^lemma1$', 'creation of an Element object' );

$element = Lingua::TreeTagger::Filter::Element->new(
    'lemma'       => 'lemma1',
    'original'    => 'original1',
    'tag'         => 'tag1',
);

#test the creation of a Lingua::TreeTagger::Filter::Element
ok( $element->lemma() eq '^lemma1$',
    'creation of an Element object,default quantifier' );
    
$element = Lingua::TreeTagger::Filter::Element->new(
    'lemma'       => 'lemma1',
    'original'    => '!original1',
    'tag'         => 'tag1',
);

#test the creation of a Lingua::TreeTagger::Filter::Element (negation)
ok( $element->original() eq '^original1$',
    'creation of an Element object,negation' );
    
#test the creation of a Lingua::TreeTagger::Filter::Element (negation)
ok( $element->get_neg_original() == 1,
    'creation of an Element object,negation (private attribute)' );
    
$element = Lingua::TreeTagger::Filter::Element->new(
    'lemma'       => 'lemma1',
    'original'    => '?original1',
    'tag'         => 'tag1',
    'neg_symbol'  => '?',
);

# Test negation with custom symbol.
ok( $element->original() eq '^original1$',
    'creation of an Element object,negation' );
    
# Test negation with custom symbol.
ok( $element->get_neg_original() == 1,
    'creation of an Element object,negation (private attribute)' );