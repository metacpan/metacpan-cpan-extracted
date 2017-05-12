#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require_ok( 'Enbld::Target::Attribute' );

throws_ok {
    Enbld::Target::Attribute->new
} qr/ABORT:'Enbld::Target::Attribute' requires name/, 'no parameter';

my $msg = qr/ABORT:Attribute 'Invalid' is invalid name/;
throws_ok {
    Enbld::Target::Attribute->new( 'Invalid' )
} qr/$msg/, 'invalid attribute name';

done_testing();
