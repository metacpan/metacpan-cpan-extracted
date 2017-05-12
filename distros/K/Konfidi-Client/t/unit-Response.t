#!perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use Konfidi::Client;

BEGIN {
    use_ok('Konfidi::Response');
}

my $kr = Konfidi::Response->new();
isa_ok($kr, "Konfidi::Response", 'response constructor from class');

my $krr = $kr->new();
isa_ok($krr, "Konfidi::Response", 'response constructor from instance');
isnt($kr, $krr, 'different response instances');

# see http://perldoc.perl.org/perltoot.html#Inheritance
dies_ok {
    Konfidi::Response::new();
} 'invoke new method as a function';

$kr = $kr->{'Response'} = 0.44;
is($kr, 0.44, 'test numify');
