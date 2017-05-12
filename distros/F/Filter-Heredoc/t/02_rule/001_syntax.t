#!perl

use strict;
use warnings;
use Test::More;

# Tests start here (test accessor interface for syntax rules)

use Filter::Heredoc::Rule qw ( hd_syntax );

my $EMPTY_STR = q{};
my $rule;
my $NONE = q{none}; 
my $POD = q{pod};        
my %syntax;

# get default ($EMPTY_STR)
%syntax = hd_syntax();
is( $syntax{pod}, $EMPTY_STR, 'default init rules');

# reset all rules with 'none' (but we only have one now) word
%syntax = hd_syntax( $NONE );
is( $syntax{pod}, $EMPTY_STR, 'zero out all rules');
   
# set one rule
%syntax = hd_syntax( $POD );
is( $syntax{pod}, $POD, 'hash value pod');

# get it again
%syntax = hd_syntax();
is( $syntax{pod}, $POD, 'hash value pod');

# reset all rules (but we only have one now).
%syntax = hd_syntax( $NONE );
is( $syntax{pod}, $EMPTY_STR, 'zero out all rules');

# set one rule (pod)
%syntax = hd_syntax( $POD );
is( $syntax{pod}, $POD, 'hash value pod');

# both tests should return the last set hash
%syntax = hd_syntax( !defined );  
is( $syntax{pod}, $POD, 'hash value pod with undef');

# nothin changes - not recognised language or keyword
%syntax = hd_syntax( $EMPTY_STR );
is( $syntax{pod}, $POD, 'hash value pod with empty string');

# finally reset all rules with 'none' rule
%syntax = hd_syntax( $NONE );
is( $syntax{pod}, $EMPTY_STR, 'zero out all rules');

# Test capatilization of 'none'
hd_syntax( $POD );
%syntax = hd_syntax( 'NONE' );
is( $syntax{pod}, $EMPTY_STR, 'All caps NONE');

hd_syntax( $POD );
%syntax = hd_syntax( 'None' );
is( $syntax{pod}, $EMPTY_STR, 'None');

hd_syntax( $POD );
%syntax = hd_syntax( 'NoNe' );
is( $syntax{pod}, $EMPTY_STR, 'NoNe');

hd_syntax( $POD );
%syntax = hd_syntax( 'nONE' );
is( $syntax{pod}, $EMPTY_STR, 'nONE');

# Fragments should not change the hash
hd_syntax( $POD );
%syntax = hd_syntax( 'non' );
is( $syntax{pod}, $POD, 'non');

hd_syntax( $POD );
%syntax = hd_syntax( 'noni' );
is( $syntax{pod}, $POD, 'noni');

done_testing (15);
