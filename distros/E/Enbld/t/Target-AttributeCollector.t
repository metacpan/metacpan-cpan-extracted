#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require_ok( 'Enbld::Target::AttributeCollector' );

my $attributes = Enbld::Target::AttributeCollector->new;
throws_ok {
    $attributes->Invalid
} qr/ABORT:'Invalid' is invalid method/, 'invalid method';

done_testing();
