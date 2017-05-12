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

my $tref;


# basic constructor.
$tref = Language::Befunge->new( {file=>'t/_resources/q.bf', syntax=>'trefunge98'} );
stdout_is { $tref->run_code } '', 'constructor worked';


# custom constructor.
$tref = Language::Befunge->new({
    syntax  => 'trefunge98',
    storage => 'Language::Befunge::Storage::Generic::Vec' });
is(ref($tref->get_storage), 'Language::Befunge::Storage::Generic::Vec', 'storage specified');
$tref = Language::Befunge->new({
    syntax   => 'trefunge98',
    wrapping => 'Language::Befunge::Wrapping::LaheySpace' });
is(ref($tref->get_wrapping), 'Language::Befunge::Wrapping::LaheySpace', 'wrapping specified');
$tref = Language::Befunge->new({
    syntax => 'trefunge98',
    ops    => 'Language::Befunge::Ops::GenericFunge98' });
ok(exists($$tref{ops}{m}), 'ops specified');
$tref = Language::Befunge->new({
    syntax => 'trefunge98',
    dims   => 4 });
is($$tref{dimensions}, 4, 'dims specified');


# basic reading.
$tref = Language::Befunge->new( {syntax=>'trefunge98'} );
$tref->read_file( "t/_resources/q.bf" );
stdout_is { $tref->run_code } '', 'read_file';


# basic storing.
$tref->store_code( <<'END_OF_CODE' );
q
END_OF_CODE
stdout_is { $tref->run_code } '', 'store_code';


# interpreter must treat non-characters as if they were an 'r' instruction.
$tref->store_code( <<'END_OF_CODE' );
01-c00p#q1.2 q
END_OF_CODE
stdout_is { $tref->run_code } '1 2 ', 'treats non-characters like "r"';


# interpreter must treat non-commands as if they were an 'r' instruction.
$tref->store_code( <<'END_OF_CODE' );
01+c00p#q1.2 q
END_OF_CODE
stdout_is { $tref->run_code } '1 2 ', 'treats non-commands like "r"';


# interpreter reads trefunge code properly, and operates in 3 dimensions, and
# knows that vectors are 3 integers.
my $code = <<"END_OF_CODE";
#v401-11x
 >..q    
\f h>      
  ^3   < 
END_OF_CODE
$tref->store_code( $code );
stdout_is { $tref->run_code } '3 4 ', 'full operation';


# rectangle() returns the original box again
chomp $code;
is( $tref->get_storage->rectangle( LBV->new(0,0,0), LBV->new(9,2,2) ),
    $code, 'rectangle works' );

