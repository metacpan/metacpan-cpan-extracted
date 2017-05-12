# -*- cperl -*-

use warnings;
use strict;
use utf8;
use Test::More tests => 10;
use Test::Warn;
use Lingua::FreeLing3::EAGLES;

my $langs = Lingua::FreeLing3::EAGLES::_hash();
isa_ok $langs => "HASH";
ok exists($langs->{pt});
ok exists($langs->{pt}{N});

my $fs = eagles(pt => "NCMS00");
is_deeply $fs => {
                  'cat' => 'nome',
                  'number' => 'singular',
                  'subcat' => 'comum',
                  'gender' => 'm'
        };

$fs = eagles(pt => "SPS");
is_deeply $fs => { cat => 'preposition' };

$fs = eagles(pt => "PX1MNOP");
is_deeply $fs => {
                  'possuidor' => 'varios',
                  'cat' => 'pronoun',
                  'number' => 'neuter',
                  'subcat' => 'possessivo',
                  'gender' => 'm',
                  'pessoa' => 'primeira',
                  'caso' => 'obliquo'
                 };

warning_is {
    $fs = eagles(pt => "XPTO");
} "XPTO not understood for language pt";

is $fs => undef;

warning_is {
    $fs = eagles(pt => 'NXMXX');
} 'NXMXX not fully understood (0X0XX) for language pt';

is_deeply $fs => {
                  'cat' => 'nome',
                  'gender' => 'm'
                 };
