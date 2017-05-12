#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Language::Befunge;
use aliased 'Language::Befunge::Vector' => 'LBV';

use Test::More tests => 11;
use Test::Output;

my $unef;


# basic constructor.
$unef = Language::Befunge->new( {file=>'t/_resources/q.bf', syntax=>'unefunge98'} );
stdout_is { $unef->run_code } '', 'basic constructor';


# custom constructor.
$unef = Language::Befunge->new({
    syntax  => 'unefunge98',
    storage => 'Language::Befunge::Storage::Generic::Vec' });
is(ref($unef->get_storage), 'Language::Befunge::Storage::Generic::Vec', 'storage specified');
$unef = Language::Befunge->new({
    syntax   => 'unefunge98',
    wrapping => 'Language::Befunge::Wrapping::LaheySpace' });
is(ref($unef->get_wrapping), 'Language::Befunge::Wrapping::LaheySpace', 'wrapping specified');
$unef = Language::Befunge->new({
    syntax => 'unefunge98',
    ops    => 'Language::Befunge::Ops::GenericFunge98' });
ok(exists($$unef{ops}{m}), 'ops specified');
$unef = Language::Befunge->new({
    syntax => 'unefunge98',
    dims   => 4 });
is($$unef{dimensions}, 4, 'dims specified');


# basic reading.
$unef = Language::Befunge->new( {syntax=>'unefunge98'} );
$unef->read_file( "t/_resources/q.bf" );
stdout_is { $unef->run_code } '', 'basic reading';


# basic storing.
$unef->store_code( <<'END_OF_CODE' );
q
END_OF_CODE
stdout_is { $unef->run_code } '', 'basic storing';


# interpreter must treat non-characters as if they were an 'r' instruction.
$unef->store_code( <<'END_OF_CODE' );
01-ap#q1.2 q
END_OF_CODE
stdout_is { $unef->run_code } '1 2 ', 'non-chars treated as "r" instruction';


# interpreter must treat non-commands as if they were an 'r' instruction.
$unef->store_code( <<'END_OF_CODE' );
01+ap#q1.2 q
END_OF_CODE
stdout_is { $unef->run_code } '1 2 ', 'non-commands treated as "r" instruction';


# unefunge interpreter treats north/south instructions as unknown characters.
$unef->store_code( <<"END_OF_CODE" );
1#q.2^3.q
END_OF_CODE
stdout_is { $unef->run_code } '1 2 ', 'north/south treated as "r" instruction';


# rectangle() just returns the original string again
is( $unef->get_storage->rectangle( LBV->new(0), LBV->new(9) ),
    '1#q.2^3.q', 'rectangle works' );

