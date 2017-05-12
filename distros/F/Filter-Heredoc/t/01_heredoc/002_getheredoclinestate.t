#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 21;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

while (<DATA>) {
    
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/, $_ ;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
    
}

__DATA__
S]#!/bin/bash
S]# source.sh
S]PROGNAME=$(basename $0)  
S]echo "Just a POD extraction test"
S]echo
I]mytext=$(cat<<END_POD
H]
H]=head1
H]
H]This program name $PROGNAME
H]
H]# This is a comment
H]
E]END_POD
S])
S]echo "---------------------------"
S]echo "$mytext"
S]echo "---------------------------"
S]echo
S]echo "All done"
S]echo
