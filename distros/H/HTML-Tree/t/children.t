#!/usr/bin/perl -T

# RT 21114 test case.  Thanks Andrew Suhachov for finding it.

use warnings;
use strict;

use Test::More tests => 3;

use HTML::TreeBuilder;

my $root = HTML::TreeBuilder->new();
my $escape
    = '<table><tr><td>One</td><td>Two</td></tr><tr><td>Three</td><td>Four</td></tr></table>';
my $html = $root->parse($escape)->eof;

my $child = $root->look_down(
    _tag => 'tr',
    sub {
        my $tr = shift;
        $tr->look_down( _tag => 'td', _parent => $tr ) ? 1 : 0;
    }
);
isa_ok( $child, 'HTML::Element', "Child found" );

my @children = $root->look_down(
    _tag => 'tr',
    sub {
        my $tr = shift;
        $tr->look_down( _tag => 'td', _parent => $tr ) ? 1 : 0;
    }
);
cmp_ok( scalar(@children), '==', '2', "2 total children found" );

my $none = $root->look_down( _tag => 'tr', sub {0} );
ok( !defined($none), 'No children found' );
