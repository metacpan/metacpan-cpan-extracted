#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;

use Juno;

ok(
    exception { Juno->new },
    'Failed to create Juno without checks',
);

my $juno;

is(
    exception { $juno = Juno->new( checks => {} ) },
    undef,
    'Successfully created Juno with empty checks',
);

isa_ok( $juno, 'Juno' );


