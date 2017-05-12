#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 4;
use Filter::Heredoc qw ( hd_getstate ); 
use Filter::Heredoc::Rule qw ( hd_syntax ); 

my %state;
my ( $state, $line );
my %rule = hd_syntax();

$rule{pod} = q{pod};  
hd_syntax ( %rule );  # set the new 'pod' rule

# Bug DBNX#1: lonely redirect cause invalid state change in ingress
# This is NOT valid shell syntax, but fix it anyway.

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash
S]echo debug with only a single redirect
S]cat <<
S]echo this should not be a heredoc


