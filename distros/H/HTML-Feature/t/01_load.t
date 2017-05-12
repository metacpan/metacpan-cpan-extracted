use strict;
use warnings;
use HTML::Feature;
use Test::More tests => 11;

my $feature = HTML::Feature->new;

isa_ok( $feature,               'HTML::Feature' );
isa_ok( $feature->front_parser, 'HTML::Feature::FrontParser' );
isa_ok( $feature->engine,       'HTML::Feature::Engine' );
is( $feature->{enc_type}, 'utf8', 'enc_type is utf8' );

can_ok( $feature, 'new' );
can_ok( $feature, 'parse' );
can_ok( $feature, 'parse_url' );
can_ok( $feature, 'parse_html' );
can_ok( $feature, 'parse_response' );
can_ok( $feature, 'front_parser' );
can_ok( $feature, 'engine' );
