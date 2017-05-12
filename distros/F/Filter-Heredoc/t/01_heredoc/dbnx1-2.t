#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 18;
use Filter::Heredoc qw ( hd_getstate );
use Filter::Heredoc::Rule qw ( hd_syntax ); 

my %state;
my ( $state, $line );
my %rule = hd_syntax();

# Bug DBNX#1: lonely redirect are most likely to ocure in POD document

$rule{pod} = q{pod}; 
hd_syntax ( %rule );  # set the new 'pod' rule

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]=head1 NAME
S]
S]Bash - forbidden constructs 
S]
S]=head1 DESCRIPTION
S]
S]This document describes what you should not do in bash
S]
S]=head1 SYNOPSIS
S]
S]	cat <<
S]
S]=head2 Examples
S]
S]Above construct is not a valid bash construct
S]
S]=cut
S]

