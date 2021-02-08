#!/usr/bin/perl

use strict;
use warnings;
use Graph;
use Graph::Line;
use Test::More tests => 1;

my $error;

eval {
    my $g = Graph->new;
    my $l = Graph::Line->new( $g );
};
if( $@ ) {
    $@ =~ s/\n$//;
    $error = $@;
}

is( $error, 'only Graph::Undirected and its derivatives accepted' );
