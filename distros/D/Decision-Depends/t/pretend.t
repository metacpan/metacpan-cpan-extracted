#! perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::TempDir::Tiny;

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( $deplist, $targets, $deps );

# try some failures first

#---------------------------------------------------

# time dependency, target doesn't exist
in_tempdir '' => sub {

    mkdir( 'data' );

    eval {
        touch( 'data/dep1' );
        ( $deplist, $targets, $deps ) = submit(
            { Pretend => 1 },
            -target => 'data/targ1',
            -depend => 'data/dep1'
        );
    };
    my $err = $@;
    ok(
        !$err && eq_hash(
            $deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => [],
                    sig  => [] } }
        ),
        'time dependency, non-existant target'
    ) or diag ( $err );

    $Decision::Depends::self->_update( $deplist, $targets );
    ok( defined $Decision::Depends::self->{State}->getTime( 'data/targ1' ),
        "update pretend time" );

};
#---------------------------------------------------


