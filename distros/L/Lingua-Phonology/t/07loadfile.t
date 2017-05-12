#!/usr/bin/perl

# This script tests reading and writing of the XML file format

use strict;
use Test::More tests => 27;
use Lingua::Phonology;
use Lingua::Phonology::Common;
#use warnings; # Uncomment for debugging

# Test read for each type


our $test = new Lingua::Phonology;
our $expect = new Lingua::Phonology;
our $get; # A var for capturing stuff inside rules

# This block does nothing other than set up the $expect object
{
    $expect->features->add_feature(
        ROOT      => { type => 'privative' },
        'Child 1' => { type => 'privative' },
        'Child 2' => { type => 'privative' },
        'Child 3' => { type => 'privative' },
        privative => { type => 'privative' },
        binary    => { type => 'binary' },
        scalar    => { type => 'scalar' }
    );
    $expect->features->add_child('ROOT', 'Child 1', 'Child 2', 'Child 3');
    $expect->features->add_child('Child 1', 'Child 3');
    $expect->features->add_child('Child 2', 'privative', 'binary', 'scalar');

    my $A = Lingua::Phonology::Segment->new($expect->features, { binary => 1 });
    my $B = Lingua::Phonology::Segment->new($expect->features, { privative => 1}); 
    my $C = Lingua::Phonology::Segment->new($expect->features, { scalar => 2 });
    my $D = Lingua::Phonology::Segment->new($expect->features, { binary => 1, privative => undef });
    $expect->symbols->add_symbol(A => $A, B => $B, C => $C, D => $D);

    my $syll = $expect->syllable;
    $syll->no_onset;
    $syll->set_complex_onset;
    $syll->set_coda;
    $syll->set_complex_coda;
    $syll->min_son_dist(3);
    $syll->max_edge_son(3);
    $syll->min_nucl_son(1);
    $syll->direction('leftward');
    $syll->sonorous({binary => 2, privative => 1});
    $syll->clear_seg(sub { not $_[-1]->BOUNDARY });
    $syll->end_adjoin(sub { $_[-1]->value('Child 1') });
    $syll->begin_adjoin(sub { $_[2]->scalar });

    my $rules = $expect->rules;
    $rules->add_rule(
        Raw => {
            tier => 'Child 2',
            domain => 'Child 1',
            direction => 'leftward',
            filter => sub { $_[0]->privative(1)  },
            where => sub { $_[0]->scalar },
            do => sub { $_[0]->binary(0) },
            result => sub { $_[0]->value('Child 2', 1) }
        },
        Extended => {
            tier => 'Child 2',
            domain => 'Child 1',
            direction => 'leftward',
            filter => sub { $_[0]->privative(1)  },
            where => sub { $_[0]->scalar },
            do => sub { $_[0]->binary(0) },
            result => sub { $_[0]->value('Child 2', 1) }
        }
    );
    $rules->order(['Raw', 'Extended'], 'Extended');
    $rules->persist('Raw', 'Raw');
}

# Test read of all sections
for ('features', 'symbols', 'syllable', 'rules') {
    ok $test->$_->loadfile('t/test.xml'), "test loadfile of $_";
    is flatten($test->$_), flatten($expect->$_), "test/expect same for $_";
}

# Test actual application of rules and syllabification
{
    my @testword = $test->symbols->segment(split //, 'CADABAD');
    my @expectword = $expect->symbols->segment(split //, 'CADABAD');

    $test->rules->apply_all(\@testword);
    $expect->rules->apply_all(\@expectword);
    is flatten(\@testword), flatten(\@expectword), 'test application of all rules';

    $test->syllable->syllabify(@testword);
    $expect->syllable->syllabify(@expectword);
    is flatten(\@testword), flatten(\@expectword), 'test syllabification';
}

# Test write/reread
{
    my $read = new Lingua::Phonology;
    my $write = new Lingua::Phonology;

    ok $write->loadfile('t/test.xml'), 'test loadfile on all';
    ok $write->savefile('t/test_out.xml'), 'test savefile';
    ok $read->loadfile('t/test_out.xml'), 'test reload saved file';

    for ('features', 'symbols', 'syllable', 'rules') {
        is flatten($read->$_), flatten($write->$_), "test $_ reloaded ok";
    }

    #unlink 't/test_out.xml';
}

# Test loading of defaults
{
    my $def = new Lingua::Phonology;
    my $def2 = new Lingua::Phonology;

    for ('features', 'symbols', 'syllable', 'rules') {
        ok $def->$_->loadfile, "test default $_";
    }
    ok $def2->loadfile, "test default on all";
    is flatten($def2), flatten($def), "test the same for individual and whole default";
}

# Test failures
{
    for ('features', 'symbols', 'syllable', 'rules') {
        ok !$test->$_->loadfile('nonesuch.xml'), "loadfile failure for $_";
    }
}

# Stringify self-referential structures correctly
sub flatten {
    my ($ref, $seen) = @_;
    return $ref if not ref $ref;

    # Tell me *where* the reused ref occurred, so equivalent structures w/
    # different refs will compile the same
    return "!reused$seen->{$ref}!" if exists $seen->{$ref};
    $seen->{$ref} = scalar keys %$seen;

    my $rv;
    no warnings 'uninitialized';
    if (_is $ref, 'HASH') {
        $rv = '{';
        $rv .= join ',', map { "$_=>" . flatten($ref->{$_}, $seen) } sort keys %$ref;
        $rv .= '}';
    }
    if (_is $ref, 'ARRAY') {
        $rv = '[' . join(',', map { flatten($_, $seen) } @$ref) . ']';
    }
    if (_is $ref, 'SCALAR') {
       $rv = "\$$$ref\$";
    }
    if (_is $ref, 'CODE') {
        $rv = "&code$seen->{$ref}&";
    }

    return $rv;
}
