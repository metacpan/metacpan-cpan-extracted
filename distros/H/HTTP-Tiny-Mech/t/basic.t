use strict;
use warnings;

use Test::More tests => 3;
use HTTP::Tiny::Mech;
use HTTP::Tiny 0.022;

my $instance = HTTP::Tiny::Mech->new();
isa_ok( $instance,         'HTTP::Tiny' );
isa_ok( $instance,         'HTTP::Tiny::Mech' );
isa_ok( $instance->mechua, 'WWW::Mechanize' );
