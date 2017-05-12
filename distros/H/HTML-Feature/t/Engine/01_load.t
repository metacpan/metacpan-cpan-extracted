use strict;
use warnings;
use HTML::Feature;
use HTML::Feature::Engine;
use Test::More tests => 3;

my $self   = HTML::Feature->new;
my $engine = HTML::Feature::Engine->new( context => $self );
isa_ok( $engine, 'HTML::Feature::Engine' );

can_ok( $engine, 'new');
can_ok( $engine, 'run');
