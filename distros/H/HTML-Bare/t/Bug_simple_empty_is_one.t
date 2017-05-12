#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'HTML::Bare', qw/htmlin/ );

my ( $ob, $root ) = HTML::Bare->simple( text => "<node att='2'><sub/></node>" ); 

ok( $root, "Got some root" );
my $attval = $root->{'node'}{'att'};
is( $attval, '2', "Got the right attribute value" );
my $sub_val = $root->{'node'}{'sub'};
is( $sub_val, '', "Got the right sub value" );