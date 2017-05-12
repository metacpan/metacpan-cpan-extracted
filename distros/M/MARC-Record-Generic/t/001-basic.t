#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'MARC::Record::Generic';
}

my $data = {
          'leader' => '01109cam a2200349 a 4500',
          'fields' => [
                        '001',
                        '   89009461 //r92',
                        '005',
                        '19991006093052.0',
                        '008',
                        '991006s1989    nyuaf   bb    00110aeng  ',
                        '010',
                        {
                          'subfields' => [
                                           'a',
                                           '89009461 //r92'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '020',
                        {
                          'subfields' => [
                                           'a',
                                           '0688064922'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '040',
                        {
                          'subfields' => [
                                           'a',
                                           'DLC',
                                           'c',
                                           'DLC',
                                           'd',
                                           'DLC'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '043',
                        {
                          'subfields' => [
                                           'a',
                                           'fe-----',
                                           'a',
                                           'n-us---'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '050',
                        {
                          'subfields' => [
                                           'a',
                                           'GN50.6.J64',
                                           'b',
                                           'A3 1989'
                                         ],
                          'ind1' => '0',
                          'ind2' => '0'
                        },
                        '082',
                        {
                          'subfields' => [
                                           'a',
                                           '569/.9',
                                           '2',
                                           '20'
                                         ],
                          'ind1' => '0',
                          'ind2' => '0'
                        },
                        '100',
                        {
                          'subfields' => [
                                           'a',
                                           'Johanson, Donald C.'
                                         ],
                          'ind1' => '1',
                          'ind2' => '0'
                        },
                        '245',
                        {
                          'subfields' => [
                                           'a',
                                           'Lucy\'s child :',
                                           'b',
                                           'the discovery of a human ancestor /',
                                           'c',
                                           'Donald Johanson and James Shreeve.'
                                         ],
                          'ind1' => '1',
                          'ind2' => '0'
                        },
                        '250',
                        {
                          'subfields' => [
                                           'a',
                                           '1st ed.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '260',
                        {
                          'subfields' => [
                                           'a',
                                           'New York :',
                                           'b',
                                           'Morrow,',
                                           'c',
                                           'c1989.'
                                         ],
                          'ind1' => '0',
                          'ind2' => ' '
                        },
                        '300',
                        {
                          'subfields' => [
                                           'a',
                                           '318 p., [16] p. of plates :',
                                           'b',
                                           'ill. (some col.) ;',
                                           'c',
                                           '24 cm.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '500',
                        {
                          'subfields' => [
                                           'a',
                                           'Includes index.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '504',
                        {
                          'subfields' => [
                                           'a',
                                           'Bibliography: p. [291]-295.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '600',
                        {
                          'subfields' => [
                                           'a',
                                           'Johanson, Donald C.'
                                         ],
                          'ind1' => '1',
                          'ind2' => '0'
                        },
                        '650',
                        {
                          'subfields' => [
                                           'a',
                                           'Anthropologists',
                                           'z',
                                           'United States',
                                           'x',
                                           'Biography.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => '0'
                        },
                        '650',
                        {
                          'subfields' => [
                                           'a',
                                           'Australopithecus afarensis.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => '0'
                        },
                        '650',
                        {
                          'subfields' => [
                                           'a',
                                           'Fossil man',
                                           'z',
                                           'Africa, East.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => '0'
                        },
                        '650',
                        {
                          'subfields' => [
                                           'a',
                                           'Anthropologists',
                                           'z',
                                           'Africa, East',
                                           'x',
                                           'Biography.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => '0'
                        },
                        '650',
                        {
                          'subfields' => [
                                           'a',
                                           'Anthropology, Prehistoric',
                                           'z',
                                           'Africa, East.'
                                         ],
                          'ind1' => ' ',
                          'ind2' => '0'
                        },
                        '653',
                        {
                          'subfields' => [
                                           'a',
                                           'Lucy (Australopithecine)'
                                         ],
                          'ind1' => '0',
                          'ind2' => ' '
                        },
                        '700',
                        {
                          'subfields' => [
                                           'a',
                                           'Shreeve, James.'
                                         ],
                          'ind1' => '1',
                          'ind2' => '0'
                        },
                        '961',
                        {
                          'subfields' => [
                                           't',
                                           '11'
                                         ],
                          'ind1' => 'w',
                          'ind2' => 'l'
                        },
                        '942',
                        {
                          'subfields' => [
                                           's',
                                           '1'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        },
                        '999',
                        {
                          'subfields' => [
                                           'c',
                                           '100',
                                           'd',
                                           '100'
                                         ],
                          'ind1' => ' ',
                          'ind2' => ' '
                        }
                      ]
        };

sub fields_are_equal {
    my ($a, $b) = @_;
    return undef unless $a->tag eq $b->tag;

    return $a->data eq $b->data
        if ($a->is_control_field);

    return undef unless $a->indicator(1) eq $b->indicator(1)
        && $a->indicator(2) eq $b->indicator(2);

    my @a_subf = $a->subfields;
    my @b_subf = $b->subfields;

    while (@a_subf) {
        my $as = shift @a_subf;
        my $bs = shift @b_subf;
        return undef unless $as->[0] eq $bs->[0] && $as->[1] eq $bs->[1];
    }

    return undef if @b_subf;

    return 1;
}

sub records_are_equal {
    my ($a, $b) = @_;

    # Our testing is destructive. Don't mutate original records.
    $b = $b->clone;

    # Leaders must match.
    return undef unless $a->leader eq $b->leader;

    # Iterate over $a's fields, removing the matches from $b.
    for my $af ($a->fields) {
        my @bfs = $b->field( $af->tag );
        return undef unless @bfs; # no matching tag by that number

        for my $bf (@bfs) {
            $b->delete_fields( $bf )
                if fields_are_equal( $af, $bf );
        }

        # If we did not delete a tag, then there was no match.
        my @now_bfs = $b->field( $af->tag );
        return undef if @now_bfs == @bfs;
    }

    # If there are fields left over in $b, records are not equal.
    return undef unless $b->fields == 0;

    # Ran the gauntlet and survived!
    return 1;
}

my $r1 = MARC::Record->new_from_generic( $data );
isa_ok $r1, 'MARC::Record';
my $data2 = $r1->as_generic();
my $r2 = MARC::Record->new_from_generic( $data2 );
is records_are_equal($r1, $r2), 1, 'Equal records';

done_testing;
