#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'HTML::Bare', qw/htmlin/ );

my ( $ob, $root ) = HTML::Bare->new( text => "<xml><ob key='1' val='test'/></xml>" );

my $set = $ob->find_by_perl( $root->{'xml'}{'ob'}, "-key eq '1'" );
ok( $set, 'Got an array back' );

my $item1 = $set->[0];
ok( $set, 'Got at least one result' );

my $val = $item1->{'val'}{'value'};
is( $val, 'test', 'Value is correct' );