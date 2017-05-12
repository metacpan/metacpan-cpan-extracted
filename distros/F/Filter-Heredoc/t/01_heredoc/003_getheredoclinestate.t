#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 10;
use Filter::Heredoc qw ( hd_getstate ); 


# Nested delimiters in the here document

my %state;
my ( $state, $line );

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/, $_ ;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
    
}

__DATA__
S]echo "Just a nested heredoc"
I] << END1 ;<<END2 
H] Hi there   
E]END1
H] Hello again   
H]# This is a comment
H]    
E]END2
S]echo "All done"
S]echo

