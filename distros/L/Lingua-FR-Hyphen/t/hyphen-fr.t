#!/usr/bin/perl
#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2015
# Update    : 21/08/2015
# AIM       : hyphens tests
#==================================================================
use strict;
use warnings;
use Carp;

use Test::More tests => 11;
use Lingua::FR::Hyphen;
use utf8;

my $hyphenator = new Lingua::FR::Hyphen;
ok( 'repré-sen-ta-tion' eq $hyphenator->hyphenate('représentation'), 'représentation' );
ok( 'Montpellier' eq $hyphenator->hyphenate('Montpellier'),            'Montpellier' );
ok( 'avo-cat' eq $hyphenator->hyphenate('avocat'),                     'avocat' );
ok( 'porte-monnaie' eq $hyphenator->hyphenate('porte-monnaie'),        'porte-monnaie' );
ok( '0102030405' eq $hyphenator->hyphenate('0102030405'),              'numbers' );
ok( 'tran-sac-tion' eq $hyphenator->hyphenate('transaction'),          'transaction' );
ok( 'consul-tant' eq $hyphenator->hyphenate('consultant'),             'consultant' );
ok( 'rubicon' eq $hyphenator->hyphenate('rubicon'),                    'rubicon' );
ok( 'déve-lop-pe-ment' eq $hyphenator->hyphenate('développement'),   'développement' );
ok( 'fécondé' eq $hyphenator->hyphenate('fécondé'),                'fécondé' );
ok( 'UNESCO' eq $hyphenator->hyphenate('UNESCO'),                      'UNESCO' );
