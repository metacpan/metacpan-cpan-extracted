#!perl

use strict;
use warnings;

use Carp;

use Test::More;
use Test::Exception;

require_ok( 'Enbld::Exception' );

throws_ok {
    croak Enbld::Exception->new( 'exception message' );
} qr/ABORT:exception message/, 'captured exception';

my $param = {
    param   =>  'parameter',
};

throws_ok {
    croak Enbld::Exception->new( 'exception message with parameter', $param );
} qr/ABORT:exception message with parameter/,
    'exception with parameter captured';

done_testing();
