#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 14;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Bug DBNX#13: Note the trailing white space after the first ingress ;
# Cause use of uninitialized value $line in pattern match (m//) ...

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');

}


__DATA__
S]#!/bin/bash
S]echo "Testing bash"
S]echo "-------------"
I]cat <<eof1; 
H]Hereline11
H]hereline21
E]eof1
S]echo back again
I]cat <<eof2
H]Hereline21
H]hereline22
E]eof2
S]echo "Back in source"
S]echo "--------------"