#! perl

use strict;
use warnings;

use Test::More;
plan( tests => 4 );

use Test::TempDir::Tiny;

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( %deps );

# try some failures first

#---------------------------------------------------

# the time dependency file does not exist.
in_tempdir '' => sub {

    eval {
        mkdir( 'data' );
        touch( 'data/targ1' );
        test_dep( -target => 'data/targ1', -depend => 'NOT_EXIST' );
    };
    my $err = $@;
    ok( $err && $err =~ /non-existant.*NOT_EXIST/, 'non-existant time dependency' )
    or diag( $err );
};

#---------------------------------------------------

# time dependency, target doesn't exist
in_tempdir '' => sub {

    eval {
        mkdir( 'data' );
        touch( 'data/dep1' );
        %deps = test_dep( -target => 'data/targ1', -depend => 'data/dep1' );
    };
    my $err = $@;
    ok(
        !$err && eq_hash(
            \%deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => [],
                    sig  => [] } }
        ),
        'time dependency, non-existant target'
    ) or diag( $err );
};

#---------------------------------------------------

# time dependency, multiple non-existant targets
in_tempdir '' => sub {

    eval {
        mkdir( 'data' );
        touch( 'data/dep1' );
        %deps = test_dep(
            -target => [ 'data/targ1', 'data/targ2' ],
            -depend => 'data/dep1'
        );
    };
    my $err = $@;
    ok(
        !$err && eq_hash(
            \%deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => [],
                    sig  => []
                },
                'data/targ2' => {
                    var  => [],
                    time => [],
                    sig  => []
                },
            }
        ),
        'time dependency, multiple non-existant targets'
    ) or diag( $err );
};

#---------------------------------------------------

# time dependency, target exists
in_tempdir '' => sub {

    eval {
        mkdir( 'data' );
        touch( 'data/targ1', 'data/dep1' );
        %deps = test_dep( -target => 'data/targ1', -depend => 'data/dep1' );
    };
    my $err = $@;
    ok(
        !$err && eq_hash(
            \%deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => ['data/dep1'],
                    sig  => [] } }
        ),
        'time dependency, target exists'
    ) or diag( $err );
};

#---------------------------------------------------

