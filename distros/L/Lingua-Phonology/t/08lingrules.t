#!/usr/bin/perl

use strict;
#use warnings; # Uncomment for debugging
use Test::More tests => 41;
use Lingua::Phonology;

my $phono = new Lingua::Phonology;
$phono->loadfile;

# Load the rules file
ok $phono->rules->loadfile('t/test_rules.xml'), 'load ling rules file';
$phono->symbols->drop_symbol('j', 'w', 'H'); # Simplifies rules where we don't want to syllabify

# Simple spell
testify('SimpleSpell', 'si', 'Si');

# Simple featural
testify('SimpleFeatural', 'by', 'bi');

# Quote values - test that strange values from the file are loaded/escaped
# correctly. Can't be done w/ testify
{
    my $s1 = $phono->segment;
    $s1->aperture(q{"''});

    ok $phono->rules->QuoteValue([$s1]), 'QuoteValue applies safely';
    is $s1->aperture, q{''`%^$><" foo}, 'result of QuoteValue as expected';
}

# Featural types - test test/assignment to all types of feature. Also can't be
# done with testify.
{
    my $s1 = $phono->segment;
    $s1->anterior(0);
    $s1->aperture(2);
    $s1->vocoid(1);

    ok $phono->rules->FeatureTypes([$s1]), 'FeatureTypes applies safely';
    is_deeply { $s1->all_values }, { anterior => 1, aperture => 3 }, 'result of FeatureTypes as expected';
}

# Deleting a segment
{
    my @w1 = word('bat', $phono);
    $phono->syllable->set_coda;
    $phono->syllable->syllabify(@w1);

    ok $phono->rules->Delete(\@w1), 'Delete applies safely';
    is $phono->symbols->spell(@w1), 'ba', 'result of Delete as expected';
}

# Inserting a segment
testify('Insert', 'ask', 'asik');

# Segment sets
testify('SegmentSet', 'adtagtam', 'ahtahtah');

# Condition set
testify('ConditionSet', 'estad', 'essas');

# Multiple segs - delete
testify('MultipleDelete', 'ska', 'Sa');

# Multiple Change
testify('MultipleChange', 'big', 'pyg');

# Multiple insert
testify('MultipleInsert', 'strap', 'satrap');

# Multiple null
testify('MultipleNull', 'kat', 'katad');

# Insert at left
testify('LboundInsert', 'sta', 'esta');

# Insert at right
testify('RboundInsert', 'pal', 'pal@');

# Check loading lingrules from add_rule
ok $phono->rules->add_rule('Test' => { linguistic => '/k/ => /?/ : _$' } ), 'linguistic add_rule';
testify('Test', 'tak', 'ta?');

# Various kinds of rules that should fail
perjure('Missing ]', '[nasal] => [*voice');
perjure('Missing [', 'voice] => [+continuant]');
perjure('Missing /', '/s/ => /S');
perjure('Missing (', '/t/|/d/) => /s/ : _/s/');
perjure('Missing )', '(/t/|/d/ => /s/ : _/s/');
perjure('Misplaced Bound', '/s/$ => /S/$');
perjure('Null in Set', '/s/(/r/|/l/|0) => /S/0');
{ local $TODO = "Fails"; perjure('Null in When', '/k/ => /"?"/ : _0/t/'); }
perjure('Set in To', '/k/ => (/g/|/h/)');

# Debugging - comment out for production
$phono->savefile('test_rules_out.xml');

sub word {
    my ($word, $phono) = @_;
    return $phono->symbols->segment(split //, $word);
}

sub testify {
    my ($rule, $in, $out) = @_;
    my @word = word($in, $phono);
    ok $phono->rules->$rule(\@word), "$rule applies safely";
    is $phono->symbols->spell(@word), $out, "result of $rule as expected";
}

sub perjure {
    my ($rule, $ling) = @_;
    ok !$phono->rules->add_rule($rule => { linguistic => $ling }), "failure of $rule";
}
