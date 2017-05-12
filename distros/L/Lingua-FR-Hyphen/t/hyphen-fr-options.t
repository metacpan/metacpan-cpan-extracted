#!/usr/bin/perl
#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2015
# Update    : 24/08/2015
# AIM       : hyphens tests
#==================================================================
use strict;
use warnings;
use Carp;

use Test::More tests => 15;
use Lingua::FR::Hyphen;
use utf8;

my $hyphenator = new Lingua::FR::Hyphen(
	{
		'min_word'         => 4,
		'min_prefix'       => 2,
		'min_suffix'       => 2,
		'cut_compounds'    => 1,
		'cut_proper_nouns' => 1,
	}
);

ok( 're/pré/sen/ta/tion' eq $hyphenator->hyphenate( 'représentation', '/' ), 'représentation' );
ok( 'Mont-pel-lier' eq $hyphenator->hyphenate('Montpellier'),                    'Montpellier' );
ok( 'avo-cat' eq $hyphenator->hyphenate('avocat'),                               'avocat' );
ok( 'porte--mon-naie' eq $hyphenator->hyphenate('porte-monnaie'),                 'porte-monnaie' );
ok( 'oui' eq $hyphenator->hyphenate('oui'),                                      'oui' );
ok( 'tran-sac-tion' eq $hyphenator->hyphenate('transaction'),                    'transaction' );
ok( 'consul-tant' eq $hyphenator->hyphenate('consultant'),                       'consultant' );
ok( 'ru-bicon' eq $hyphenator->hyphenate('rubicon'),                             'rubicon' );
ok( 'dé-ve-lop-pe-ment' eq $hyphenator->hyphenate('développement'),            'développement' );
ok( 'fé-con-dé' eq $hyphenator->hyphenate('fécondé'),                        'fécondé' );
ok( 'UNESCO' eq $hyphenator->hyphenate('UNESCO'),                                'UNESCO' );
ok( 'mai-son' eq $hyphenator->hyphenate('maison'),                               'maison' );
ok( 'Bon-jour tout le monde' eq $hyphenator->hyphenate('Bonjour tout le monde'), 'Phrase' );

SKIP: {
	eval { my $hyphenator_bad = Lingua::FR::Hyphen->new( 'min_word' => 4 ); };
	like( $@, qr/You have to use a hash/, 'ref HASH' );
}
SKIP: {
	eval { my $hyphenator_bad = Lingua::FR::Hyphen->new({'bad_option' => 4 }); };
	like( $@, qr/option not exists in/, 'Bad option' );
}