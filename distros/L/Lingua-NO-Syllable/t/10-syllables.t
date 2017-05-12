#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use Lingua::NO::Syllable;

my %tests = (
    'Bare'          => 2, # Ba-re
    'Bavian'        => 3, # Bav-i-an
    'Dokumentere'   => 5, # Dok-u-men-te-re
    'Fiolin'        => 3, # Fi-o-lin
    'Helikopter'    => 4, # He-li-kop-ter
    'Husk'          => 1, # Husk
    'Idé'           => 2, # I-de (normalized)
    'Idè'           => 2, # I-de (normalized)
    'Løyve'         => 2, # Løy-ve
    'Øy'            => 1, # Øy
    'Påstander'     => 3, # På-stand-er
    'Restaurant'    => 3, # Rest-au-rant
    'Saumfare'      => 3, # Saum-fa-re
    'Soyabønner'    => 4, # So-ya-bønn-er
    'Tyrannosaurus' => 5, # Tyr-ann-o-sau-rus
    'Veikro'        => 2, # Vei-kro
    'Å'             => 1, # Å
);

plan tests => scalar( keys %tests );

foreach ( keys %tests ) {
    is( syllables($_), $tests{$_}, "'" . $_ . "' passed!" );
}

done_testing;
