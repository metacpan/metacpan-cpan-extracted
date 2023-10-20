#!/usr/bin/perl

use strict;
use warnings;
use Graph;
use Graph::MoreUtils qw( line );
use Test::More tests => 1;

my $error;

eval {
    my $g = Graph->new;
    my $l = line( $g );
};
if( $@ ) {
    $@ =~ s/\n$//;
    $error = $@;
}

is( $error, 'only Graph::Undirected and its derivatives are accepted' );
