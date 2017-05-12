#!/usr/bin/env perl
use strict; use warnings; 
no warnings 'redefine'; no warnings 'once';
use Test::More; use File::Spec; use File::Basename;

use rlib '../lib';

note( "Testing interpret_flags" );

BEGIN {
    require_ok( 'Devel::Trepan::CmdProcessor::Command::Disassemble' );
}

my @tests =
 ( [0b000000, ''], 
   [0b000001, ': want void'], 
   [0b000010, ': want scalar'], 
   [0b000011, ': want list'], 
   [0b001101, ': parenthesized, want kids, want void'], 
   [0b100011, ': modify lvalue, want list']
 );

for my $pair (@tests) {
    my ($flag, $expect) = @$pair;
    is(Devel::Trepan::CmdProcessor::Command::Disassemble::interpret_flags($flag),
       $expect, sprintf "flag: 0b%b", $flag);
}
done_testing();
