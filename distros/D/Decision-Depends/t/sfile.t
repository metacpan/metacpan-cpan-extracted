#! perl

use strict;
use warnings;

use Test::More;
plan( tests => 5 );

use Test::TempDir::Tiny;

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

#---------------------------------------------------

# the status file does not exist.
in_tempdir '' => sub {

    mkdir( 'data' );

    my ( $deplist, $targets, $deps );

    eval {
        touch( 'data/dep1' );
        ( $deplist, $targets, $deps ) = submit(
            -sfile  => 'data/targ1',
            -depend => 'data/dep1',
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
        'non-existant status file'
    ) or diag( $err );


    eval { $Decision::Depends::self->_update( $deplist, $targets ); };
    $err = $@;

    ok( !$err && -f 'data/targ1', 'sfile update of non-existant sfile' )
      or diag( $err );

};

#---------------------------------------------------

# the status linked file does not exist.
in_tempdir '' => sub {

    mkdir( 'data' );

    my ( $deplist, $targets, $deps );

    eval {
        touch( 'data/dep1' );
        ( $deplist, $targets, $deps ) = submit(
            '-slink=data/targ2' => 'data/targ1',
            -depend             => 'data/dep1',
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
        'non-existant status file'
    ) or diag( $err );

    eval { $Decision::Depends::self->_update( $deplist, $targets ); };
    $err = $@;
    ok( !$err && -f 'data/targ1', 'slink update of non-existant sfile' )
      or diag( $err );

    eval {
        touch( 'data/targ2', 'data/targ3', 'data/targ1' );
        ( $deplist, $targets, $deps ) = submit(
            { NoInit => 1 },
            -target => 'data/targ3',
            -depend => 'data/targ2',
        );
    };
    $err = $@;

    ok(
        !$err && eq_hash(
            $deps,
            {
                'data/targ3' => {
                    var  => [],
                    time => ['data/targ1'],
                    sig  => [] } }
        ),
        "check against slink'ed target"
    ) or diag( $err );

};

#---------------------------------------------------



