#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use MARC::Field;

eval {
    my $field = MARC::Field->new( '245', '0', '4', () );
};
like( $@, qr/must have at least one subfield/, 'RT#67094: croak with correct error if trying to create field without subfields');
