#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'IO::Handle::Prototype';

my $buf = '';

my $fh = IO::Handle::Prototype->new(
    print => sub {
        $buf .= $_[1];
    },
);

isa_ok( $fh, "IO::Handle::Prototype" );
isa_ok( $fh, "IO::Handle" );

can_ok( $fh, qw(getline read print write) );

eval { $fh->print("foo") };
is( $@, '', "no error" );
is( $buf, "foo", "callback worked" );

eval { $fh->getline };
like( $@, qr/getline/, "dies on missing callback" );

eval { $fh->write("foo") };
like( $@, qr/write/, "dies on missing callback" );

done_testing;

# ex: set sw=4 et:
