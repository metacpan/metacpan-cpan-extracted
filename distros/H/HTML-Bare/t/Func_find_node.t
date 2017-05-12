#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'HTML::Bare', qw/htmlin/ );

my ( $ob, $root ) = HTML::Bare->new( text => "<xml><ob><key>0</key><val>a</val></ob></xml>" );

my $node = $ob->find_node( $root->{'xml'}, 'ob', key => 0 );

ok( $node, 'Got something back' );

my $val = $node->{'val'}{'value'};
is( $val, 'a', 'Value Matches' );