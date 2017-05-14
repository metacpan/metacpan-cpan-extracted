#!/usr/bin/perl

use strict;
use warnings;

use Lingua::TreeTagger::Filter;


use Test::More tests => 58; #58

# Test taggetext.
# Tagging a trial text.
my $tagger = Lingua::TreeTagger->new(
    'language' => 'english',
    'options'  => [qw( -token -lemma -no-unknown )],
);

my $text   = 'this is a trial this is a trial this is a trial this is a trial this is a trial';
my $tagged_text = $tagger->tag_text(\$text);


################################################################################
#TEST FILTER
################################################################################

my $filter = Lingua::TreeTagger::Filter->new();

# Test the creation of a Lingua::TreeTagger::Filter.
ok( $filter->get_sequence(), 'creation of an Filter object' );

# Test creation with a sequence in line.
my $string = 'tag=NOM original=est#tag=!ADJ';
$filter = Lingua::TreeTagger::Filter->new($string);

my $test_new           = $filter->get_sequence();
my $current_element    = $test_new->[0];


ok(
    $current_element->tag() eq '^NOM$' &&
      $current_element->original() eq '^est$',
    'test entry_line: simple case',
);
# Testing 2nd element.
$current_element = $test_new->[1];
ok(
    $current_element->tag() eq '^ADJ$' &&
      $current_element->get_neg_tag() == 1,
    'test entry_line: negation case',
);


$filter = Lingua::TreeTagger::Filter->new();
$filter->add_element();

$test_new        = $filter->get_sequence();
my @tab_test_new = @$test_new;
$test_new = $tab_test_new[0];

ok(
    $test_new->original()   eq '.'
      && $test_new->tag()   eq '.'
      && $test_new->lemma() eq '.',
'add_element: creation of a new element (default values) and add to sequence'
);

$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemma0',
    'original'   => 'original0',
    'tag'        => 'tag0',
    'quantifier' => 'quantifier0',
);

$test_new     = $filter->get_sequence();
@tab_test_new = @$test_new;
$test_new     = $tab_test_new[0];

ok( $test_new->lemma() eq '^lemma0$',
    'add_element: creation of a new element and add to sequence' );
    
# Testing attribute without anchor
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'        => 'lemma0',
    'anchor_lemma' => '0',
);

$test_new     = $filter->get_sequence();
@tab_test_new = @$test_new;
$test_new     = $tab_test_new[0];

ok( $test_new->lemma() eq 'lemma0',
    'add_element: attribute without anchor' );



eval { $filter->add_element(
  'lemma'          => 'lemma0',
  'original'       => 'original0',
  'tag'            => 'tag0',
  'quantifier'     => 'quantifier0',
  'position'       => 10,
  ) 
};
like(
    $@,
    qr/out of index/,
    'add_element: out of index'
);

# Add with an index.
my $error = $filter->add_element(
    'lemma'          => 'lemma_index',
    'original'       => 'original0',
    'tag'            => 'tag0',
    'quantifier'     => 'quantifier0',
    'position'       => 1,
);
$test_new     = $filter->get_sequence();
@tab_test_new = @$test_new;
$test_new     = $tab_test_new[1];

ok( $test_new->lemma() eq '^lemma_index$',
    'add_element: creation of a new element and add to sequence (with index)' );

my $element = Lingua::TreeTagger::Filter::Element->new(
    'lemma'       => 'lemma1',
    'original'    => 'original1',
    'tag'         => 'tag1',
);

$filter->add_element( element_object => $element, );

$test_new     = $filter->get_sequence();
@tab_test_new = @$test_new;
$test_new     = $tab_test_new[2];

ok( $test_new->lemma() eq '^lemma1$',
    'add_element: add an existing element to sequence' );

my $removed_element = $filter->remove_element( 2 );

ok(
    $removed_element->lemma() eq '^lemma1$',
    'remove an element from sequence, return value'
);

$test_new = $filter->get_sequence();
ok( length(@$test_new) == 1,
    'remove an element from sequence, length of array' );

eval {$filter->remove_element( 2 ) };
like(
    $@,
    qr/the asked element is not part of the sequence \n/,
    'remove an element from sequence, out of index value'
);

# Controlling the negations.
my $filter_neg = Lingua::TreeTagger::Filter->new();
$filter_neg->add_element(
    'lemma'      => '!lemma0',
    'original'   => '!original0',
    'tag'        => '!tag0',
    'quantifier' => 'quantifier0',
);

$test_new     = $filter_neg->get_sequence();
$test_new     = $test_new->[0];

# Lemma.
ok( $test_new->lemma() eq '^lemma0$'
    && $test_new->get_neg_lemma() == 1,
    'add_element: negation of lemma' );
    
# Original.
ok( $test_new->original() eq '^original0$'
    && $test_new->get_neg_original() == 1,
    'add_element: negation of original' );
    
# Tag.
ok( $test_new->tag() eq '^tag0$'
    && $test_new->get_neg_tag() == 1,
    'add_element: negation of tag' );
   
# Testing the init_with_string_method.
my $filter_entry = Lingua::TreeTagger::Filter->new(); 
my $entry = 'tag=NOM original=est#tag=!ADJ';
$filter_entry->init_with_string($entry);

$test_new           = $filter_entry->get_sequence();
$current_element    = $test_new->[0];


ok(
    $current_element->tag() eq '^NOM$' &&
      $current_element->original() eq '^est$',
    'test entry_line: simple case',
);
# Testing 2nd element.
$current_element = $test_new->[1];
ok(
    $current_element->tag() eq '^ADJ$' &&
      $current_element->get_neg_tag() == 1,
    'test entry_line: negation case',
);

################################################################################
#TEST FILTER -> extract_ngrams
################################################################################

my $result = $filter->extract_ngrams( $tagged_text, 2);

$test_new     = $result->get_hits();

ok( @$test_new == 19, 'test extract_ngrams: test 1, seq_length = 2' );

$result = $filter->extract_ngrams( $tagged_text, 3);

$test_new     = $result->get_hits();

ok( @$test_new == 18, 'test extract_ngrams: test 1, seq_length = 2' );


################################################################################
#TEST FILTER -> _compares_element
################################################################################

my $filter_element = Lingua::TreeTagger::Filter::Element->new(
    'lemma'       => 'lemma1',
    'original'    => 'original1',
    'tag'         => 'tag1',
    'is_SGML_tag' => '0',
);

my $token = Lingua::TreeTagger::Token->new(
    'lemma'       => 'lemma1',
    'original'    => 'original1',
    'tag'         => 'tag1',
    'is_SGML_tag' => '0',
);

ok( $filter->_compare_elements( $token, $filter_element ) == 1,
    'test _compare_element (simple)' );

################################################################################
#TEST FILTER -> _compare
################################################################################

# Simple case match/quantifier = 1.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'    => 'lemma1',
    'original' => 'original1',
    'tag'      => 'tag1',
);

$result =
  Lingua::TreeTagger::Filter::Result->new( taggedtext => $tagged_text, );

my $hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 0,
    'sequence_length'        => 0,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 0,
);
my %hash_return = %$hash_return_ref;

# Controlling the returned values.
ok(
    $hash_return{filter_index} == 0 && $hash_return{start_position} == 1,
    'test _compare simple case: case match/quantifier = 1'
);

# Controlling the inserted result.
my $ref_hits = $result->get_hits;
my @tab_hits = @$ref_hits;
my $hit      = $tab_hits[0];

ok(
    $hit->get_sequence_length == 1 && $hit->get_begin_index == 0,
    'test _compare simple case: case match/quantifier = 1, inserted, object'
);

# Controlling case match/quantifier = 4.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemma1',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '4',
);

$result =
  Lingua::TreeTagger::Filter::Result->new( taggedtext => $tagged_text, );

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 0,
    'sequence_length'        => 0,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 2,
);
%hash_return = %$hash_return_ref;

# Controlling the returned values.
ok(
    $hash_return{filter_index} == 0
      && $hash_return{start_position} == 0
      && $hash_return{counter_current_filter} == 3,
    'test _compare case: case match/quantifier = 4 (must increment counter)'
);

# Controlling case match/quantifier = 4.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemma1',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '4',
);

$result =
  Lingua::TreeTagger::Filter::Result->new( taggedtext => $tagged_text, );

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 0,
    'sequence_length'        => 0,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 3,
);
%hash_return = %$hash_return_ref;

# Controlling the returned values.
ok(
    $hash_return{filter_index} == 0
      && $hash_return{start_position} == 1
      && $hash_return{counter_current_filter} == 0,
    'test _compare case: case match/quantifier = 4 (must create a new hit)'
);

# Controlling case: match and quantifier allows to keep the same filter element.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemma1',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '*',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 0,
    'sequence_length'        => 0,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 0,
    'text_length'            => 100,
);

%hash_return = %$hash_return_ref;

# Controlling the returned values.
ok( $hash_return{start_position} == 0 && $hash_return{sequence_length} == 1,
    'test _compare case: case match/quantifier = * or +' );

# Controlling case: no match simple case.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemmo',
    'original'   => 'original',
    'tag'        => 'tag1',
    'quantifier' => '1',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 0,
    'sequence_length'        => 0,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 0,
);

%hash_return = %$hash_return_ref;

# Controlling the returned values.
ok( $hash_return{start_position} == 1 && $hash_return{sequence_length} == 0,
    'test _compare case: case no match simple case' );

# Controlling case: no match /case of complete sequence.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemmo',
    'original'   => 'original',
    'tag'        => 'tag1',
    'quantifier' => '*',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 0,
    'sequence_length'        => 4,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 1,
);

%hash_return = %$hash_return_ref;

# Controlling the returned values.
ok(
    $hash_return{start_position} == 1 && $hash_return{sequence_length} == 0,
    'test _compare case: no match /case of complete sequence'
);

# Controlling case: no match case of quantifier ?.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemmo',
    'original'   => 'original',
    'quantifier' => '?',
);

$filter->add_element(
    'lemma'      => 'lemma1',
    'original'   => 'original',
    'tag'        => 'tag1',
    'quantifier' => '1',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 0,
    'sequence_length'        => 0,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 0,
);

%hash_return = %$hash_return_ref;

# Controlling the inserted result.
$ref_hits = $result->get_hits;
@tab_hits = @$ref_hits;
$hit      = $tab_hits[0];

ok(
    $hit->get_sequence_length == 1 && $hit->get_begin_index == 0,
    'test _compare case: no match/case of quantifier ?'
);

#####################################
#controlling case: quantifier = {}  #
#####################################
# No match, sequence aborted.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemmo',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '{2,3}',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 5,
    'sequence_length'        => 4,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 1,
);

%hash_return = %$hash_return_ref;
ok(
    $hash_return{start_position} == 6 && $hash_return{sequence_length} == 0,
    'test _compare case: quantifier {}, no match, abort sequence'
);

# No match, sequence validated.
$filter = Lingua::TreeTagger::Filter->new();
$result =
  Lingua::TreeTagger::Filter::Result->new( taggedtext => $tagged_text, );

$filter->add_element(
    'lemma'      => 'lemmo',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '{2,3}',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 5,
    'sequence_length'        => 4,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 2,
);

%hash_return = %$hash_return_ref;

# Controlling the inserted result.
$ref_hits = $result->get_hits;
@tab_hits = @$ref_hits;
$hit      = $tab_hits[0];
ok(
    $hit->get_sequence_length == 4 && $hit->get_begin_index == 5,
    'test _compare case: quantifier {}, no match, validated sequence'
);

# Match, not yet reached the superior limit.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemma1',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '{2,3}',
);

$hash_return_ref = $filter->_compare(
    'filter_index'          => 0,
    'start_position'        => 5,
    'sequence_length'        => 4,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 1,
    'text_length'            => 100,
);

%hash_return = %$hash_return_ref;
ok(
    $hash_return{start_position} == 5 && $hash_return{sequence_length} == 5,
'test _compare case: quantifier {}, match not yet reached the superior limit'
);

# Quantifier {single value}, match not yet reached the superior limit.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => 'lemma1',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '{4}',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 5,
    'sequence_length'        => 4,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 1,
);

%hash_return = %$hash_return_ref;
ok(
    $hash_return{start_position} == 5 && $hash_return{sequence_length} == 5,
'test _compare case: quantifier {single value}, match not yet reached the superior limit'
);

# Match, superior limit reached.
$filter = Lingua::TreeTagger::Filter->new();
$result =
  Lingua::TreeTagger::Filter::Result->new( taggedtext => $tagged_text, );

$filter->add_element(
    'lemma'      => 'lemma1',
    'original'   => 'original1',
    'tag'        => 'tag1',
    'quantifier' => '{2,3}',
);

$hash_return_ref = $filter->_compare(
    'filter_index'           => 0,
    'start_position'         => 5,
    'sequence_length'        => 4,
    'token'                  => $token,
    'result'                 => $result,
    'counter_current_filter' => 2,
);

%hash_return = %$hash_return_ref;

# Controlling the inserted result.
$ref_hits = $result->get_hits;
@tab_hits = @$ref_hits;
$hit      = $tab_hits[0];
ok(
    $hit->get_sequence_length == 5 && $hit->get_begin_index == 5,
    'test _compare case: quantifier {}, no match, validated sequence'
);

# Testing result with negation.
# Creating a filter.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    original   => '!is',
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok( @$test_new == 15, 'test apply: comparison with negation' );

################################################################################
#TEST FILTER -> _substitute_attribute
################################################################################

# Case: match, no change

my @substitute = $filter->_substitute_attribute(
  'filter_attribute'     => ".",
  'filter_substitute'    => ".",
  'filter_neg_attribute' => 0,
  'token_attribute'      => "is",  
);

ok ( $substitute[1] eq "is" && $substitute[0] ==1, 
  'test _substitute_attribute: match, no change');

# Case: match, attribute = ./ sub = test

@substitute = $filter->_substitute_attribute(
  'filter_attribute'     => ".",
  'filter_substitute'    => "test",
  'filter_neg_attribute' => 0,
  'token_attribute'      => "is",  
);

ok ( $substitute[1] eq "test" && $substitute[0] ==1, 
  'test _substitute_attribute: match, attribute = ./ sub = test');
  
# Case: match, attribute = is/ sub = test

@substitute = $filter->_substitute_attribute(
  'filter_attribute'     => "is",
  'filter_substitute'    => "test",
  'filter_neg_attribute' => 0,
  'token_attribute'      => "is",  
);

ok ( $substitute[1] eq "test" && $substitute[0] ==1, 
  'test _substitute_attribute: match, attribute = is/ sub = test');

# Case: match, attribute = is (with neg)/ sub = test

@substitute = $filter->_substitute_attribute(
  'filter_attribute'     => "neg",
  'filter_substitute'    => "test",
  'filter_neg_attribute' => 1,
  'token_attribute'      => "is",  
);

ok ( $substitute[1] eq "test" && $substitute[0] ==1, 
  'test _substitute_attribute: match, attribute = is (with neg)/ sub = test');
  
# Case: no match

@substitute = $filter->_substitute_attribute(
  'filter_attribute'     => "neg",
  'filter_substitute'    => "test",
  'filter_neg_attribute' => 0,
  'token_attribute'      => "is",  
);

ok ( $substitute[0] == 0, 
  'test _substitute_attribute: no match');
  
################################################################################
#TEST FILTER -> _substitute_attribute
################################################################################

# Match, no change
$token = Lingua::TreeTagger::Token->new(
  'is_SGML_tag' => 0,
  'original'    => 'is',
  'lemma'       => 'be',
  'tag'         => 'VBZ',
);

$filter_element = Lingua::TreeTagger::Filter::Element->new({}); 

@substitute = $filter->_substitute_elements( $token, $filter_element );

ok( $substitute[0] == 1, 'test _substitute_elements: match, no change');

# Match, change tag value
$token = Lingua::TreeTagger::Token->new(
  'is_SGML_tag' => 0,
  'original'    => 'is',
  'lemma'       => 'be',
  'tag'         => 'VBZ',
);

$filter_element = Lingua::TreeTagger::Filter::Element->new({
  sub_tag => 'test',
}); 

@substitute = $filter->_substitute_elements( $token, $filter_element );
my $change  = $substitute[1];

ok( $change->tag() eq 'test', 
  'test _substitute_elements: match, change tag value');
  
# No match
$token = Lingua::TreeTagger::Token->new(
  'is_SGML_tag' => 0,
  'original'    => 'is',
  'lemma'       => 'be',
  'tag'         => 'VBZ',
);

$filter_element = Lingua::TreeTagger::Filter::Element->new({
  tag => 'test',
}); 

@substitute = $filter->_substitute_elements( $token, $filter_element );

ok( $substitute[0] == 0, 
  'test _substitute_elements: match, change tag value');  
################################################################################
#TEST FILTER -> apply
################################################################################

# Simple case.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'original'   => 'is',
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok( @$test_new == 5, 'test apply: simple case' );

# Simple case with quantifier 2.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'original'   => 'is',
);
$filter->add_element(
    'quantifier'   => 2,
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok( @$test_new == 5, 'test apply: simple case with quantifier 2' );

# Test apply, quantifier *
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original' => 'is',
);

$filter->add_element(
  'quantifier' => '*',
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 5, 'test apply: quantifier *' );

# Test apply, quantifier *
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original'   => 'is',
  'quantifier' => '*',
);

$filter->add_element();

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 20, 'test apply: quantifier * (2)' );

$hit = $test_new->[1];

ok(  $hit->get_sequence_length() == 2, 'test apply: quantifier * (2bis)' );

# Test apply, quantifier +
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original'   => 'is',
  'quantifier' => '+',
);

$filter->add_element();

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 5, 'test apply: quantifier + ' );

# Test apply, quantifier +
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original' => 'is',
);

$filter->add_element(
  'quantifier' => '+',
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 5, 'test apply: quantifier + (1)' );

$hit = $test_new->[2];

ok(  $hit->get_sequence_length() == 11, 'test apply: quantifier + (1bis)' );

# Test apply, quantifier ?
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original'   => 'is',
  'quantifier' => '?',
);

$filter->add_element();

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 20, 'test apply: quantifier ? (1)' );

# Test apply, quantifier ?
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original' => 'is',
);

$filter->add_element(
  'quantifier' => '?',
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 5, 'test apply: quantifier ? (2)' );

$hit = $test_new->[1];

ok(  $hit->get_sequence_length() == 2, 'test apply: quantifier ? (2bis)' );

# Test apply, quantifier {}
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original'   => 'is',
  'quantifier' => '{0,2}',
);

$filter->add_element();

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 20, 'test apply: quantifier {} (1)' );

# Test apply, quantifier {}.
$filter = Lingua::TreeTagger::Filter -> new ();

$filter->add_element(
  'original' => 'is',
);

$filter->add_element(
  'quantifier' => '{0,2}',
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$test_new     = $result->get_hits();

ok(  @$test_new == 5, 'test apply: quantifier {}(2)' );

$hit = $test_new->[1];

ok(  $hit->get_sequence_length() == 3, 'test apply: quantifier {} (2bis)' );



################################################################################
#TEST FILTER -> substitute
################################################################################
# Creating a filter.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'original'     => 'this',
    'sub_original' => 'the',
);

# Apply the filter to the taggedtext.
$result = $filter->substitute($tagged_text);

$test_new      = $result->sequence();
my $result_sub = $test_new->[0];

ok( $result_sub->original() eq 'the', 'test substitute: simple case' );

# Creating a filter.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'original'     => 'is',
);
$filter->add_element(
    'quantifier'   => 2,
    'sub_original' => 'test',
);
# Apply the filter to the taggedtext.
$result = $filter->substitute($tagged_text);

$test_new      = $result->sequence();
$result_sub = $test_new->[3];
ok( $result_sub->original() eq 'test', 
  'test substitute: quantifier = 2' );