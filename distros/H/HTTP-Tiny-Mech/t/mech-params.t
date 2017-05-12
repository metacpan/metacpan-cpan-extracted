
use strict;
use warnings;

use Test::More tests => 6;
use HTTP::Tiny::Mech;
use HTTP::Tiny 0.022;
use WWW::Mechanize;

BEGIN {

  package Foo;
  @Foo::ISA = ('WWW::Mechanize');
}

BEGIN {

  package Bar;
  @Bar::ISA = ('WWW::Mechanize');
}
my $instance = HTTP::Tiny::Mech->new( mechua => Foo->new(), );
isa_ok( $instance,         'HTTP::Tiny' );
isa_ok( $instance,         'HTTP::Tiny::Mech' );
isa_ok( $instance->mechua, 'WWW::Mechanize' );
isa_ok( $instance->mechua, 'Foo' );
$instance->mechua( Bar->new() );
isa_ok( $instance->mechua, 'WWW::Mechanize' );
isa_ok( $instance->mechua, 'Bar' );
