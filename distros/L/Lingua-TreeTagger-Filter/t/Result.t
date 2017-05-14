#!/usr/bin/perl

use strict;
use warnings;

use Lingua::TreeTagger::Filter;

use Test::More tests => 8;

# Test taggetext.
# Tagging a trial text.
my $tagger = Lingua::TreeTagger->new(
    'language' => 'english',
    'options'  => [qw( -token -lemma -no-unknown )],
);

my $text   = 'this is a trial this is a trial this is a trial this is a trial this is a trial';
my $tagged_text = $tagger->tag_text(\$text);

################################################################################
#TEST RESULT
################################################################################
my $result =
  Lingua::TreeTagger::Filter::Result->new( taggedtext => $tagged_text, );

ok( $result->get_hits(), "creating a Result object", );

$result->add_element(
    'begin_index'     => 99,
    'sequence_length' => 3,
);

my $test_new     = $result->get_hits();
my @tab_test_new = @$test_new;
$test_new     = $tab_test_new[0];

ok( $test_new->get_begin_index() == 99, 'add_element to the hits' );



#############
#as_text() #
############

# Creating a filter.
my $filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => '.',
    'original'   => 'xxxxx',
    'tag'        => '.',
    'quantifier' => "1",
);
$filter->add_element(
    'lemma'      => '.',
    'original'   => 'a',
    'tag'        => '.',
    'quantifier' => "1",
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

my $ref_hits = $result->get_hits;
my @tab_hits = @$ref_hits;
my $hit      = $tab_hits[0];
ok( !$result->as_text(), "test as_text: no match" );
# Same test with as_XML method.
ok( !$result->as_XML(), "test as_XML: no match" );

# Creating a filter.
$filter = Lingua::TreeTagger::Filter->new();

$filter->add_element(
    'lemma'      => '.',
    'original'   => '.',
    'tag'        => 'VBZ',
    'quantifier' => "1",
);
$filter->add_element(
    'lemma'      => '.',
    'original'   => '.',
    'tag'        => 'DT',
    'quantifier' => "1",
);

# Apply the filter to the taggedtext.
$result = $filter->apply($tagged_text);

$ref_hits = $result->get_hits;
@tab_hits = @$ref_hits;
$hit      = $tab_hits[0];

my $returned_string;

for ( my $i = 0 ; $i < 5 ; $i++ ) {
    $returned_string .= "matching sequence: " . ( $i + 1 ) . "\n";
    $returned_string .= "is\tVBZ\tbe\n";
    $returned_string .= "a\tDT\ta\n\n";

}
ok( $result->as_text() eq $returned_string, 'test as_text: simple case' );

# Method as_text with user's parameters.
$returned_string = "";

for ( my $i = 0 ; $i < 5 ; $i++ ) {
    $returned_string .= "matching sequence: " . ( $i + 1 ) . "\n";
    $returned_string .= "be\tis\tVBZ\n";
    $returned_string .= "a\ta\tDT\n\n";

}

# Creating the HASH reference.
my @fields = qw ( lemma original tag );
my $ref_parameter = {
  fields => \@fields,
}; 
is( $result->as_text($ref_parameter),$returned_string, 
  "test as_text: user's parameters" );
  
############
#as_XML()  #
############

# As_XML: simple case.
$returned_string = "";

for ( my $i = 0 ; $i < 5 ; $i++ ) {
    $returned_string .= "<seq number=\"" . ($i+1) . "\">\n";
    $returned_string .= "<w lemma=\"be\" type=\"VBZ\">is</w>\n";
    $returned_string .= "<w lemma=\"a\" type=\"DT\">a</w>\n";
    $returned_string .= "</seq>\n";

}
ok( $result->as_XML() eq $returned_string, 'test as_XML: simple case' );

# As_XML: user's parameter.
$returned_string = "";

for ( my $i = 0 ; $i < 5 ; $i++ ) {
    $returned_string .= "<sequence number=\"" . ($i+1) . "\">\n";
    $returned_string .= "<word lemma=\"be\" type=\"VBZ\">is</word>\n";
    $returned_string .= "<word lemma=\"a\" type=\"DT\">a</word>\n";
    $returned_string .= "</sequence>\n";

}

$ref_parameter = {
  'sequence' => 'sequence',
  'element'  => 'word',
};
is( $result->as_XML($ref_parameter), $returned_string, 
  "test as_XML:user's parameters" );
  

