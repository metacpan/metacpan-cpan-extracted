package HTTP::Balancer::Actor::Buzz;
use Modern::Perl;
use Moose;
extends qw(HTTP::Balancer::Actor);

our $NAME = "Buzz";

sub start {}

sub stop {}

1;
__DATA__
Buzz Config
: for $backends -> $backend {
backend <: $backend :>;
: }
