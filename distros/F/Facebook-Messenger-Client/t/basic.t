#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'No access token provided!'
	unless( $ENV{GRAPH_ACCESS_TOKEN} );

require_ok( 'Facebook::Messenger::Client' );

my $client = Facebook::Messenger::Client->new();
isa_ok( $client, 'Facebook::Messenger::Client' );
can_ok( $client, qw( access_token send send_text get_user ) );

done_testing();
