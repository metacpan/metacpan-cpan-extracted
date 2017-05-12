#! perl

use strict;
use warnings;

use Test::More;
plan( tests => 6 );

use Test::TempDir::Tiny;

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( $deplist, $targets, $deps );

#---------------------------------------------------

# non-existant signature file
in_tempdir '' => sub {
    eval {
        mkdir( 'data' );
        touch( 'data/targ1' );
        ( $deplist, $targets, $deps ) = submit(
            -target => 'data/targ1',
            -sig    => 'data/sig1'
        );
    };
    ok( $@ && $@ =~ /non-existant signature/, 'non-existant signature file' );

};
#---------------------------------------------------

# no signature on file
in_tempdir '' => sub {
    eval {
        mkdir( 'data' );
        mkfile( 'data/sig1', 'contents' );
        touch( 'data/targ1', 'data/sig1' );
        ( $deplist, $targets, $deps ) = submit(
            -target => 'data/targ1',
            -sig    => 'data/sig1'
        );
    };
    ok(
        !$@ && eq_hash(
            $deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => [],
                    sig  => ['data/sig1'] } }
        ),
        'no signature on file'
    ) or diag( $@ );

};

#---------------------------------------------------

# same signature on file
in_tempdir '' => sub {
    eval {
        mkdir( 'data' );
        mkfile( 'data/sig1', 'contents' );
        touch( 'data/targ1', 'data/sig1' );
        my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

        ( $deplist, $targets, $deps ) = submit(
            -target => 'data/targ1',
            -sig    => 'data/sig1',
            sub {
                $Decision::Depends::self->{State}
                  ->setSig( 'data/targ1', 'data/sig1', $sig );
            } );

    };
    ok( !$@ && eq_hash( $deps, {} ), 'same signature on file' )
      or diag( $@ );

};
#---------------------------------------------------

# different signature on file
in_tempdir '' => sub {
    eval {
        mkdir( 'data' );
        mkfile( 'data/sig1', 'contents' );
        touch( 'data/targ1', 'data/sig1' );
        my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

        mkfile( 'data/sig1', 'contents2' );

        ( $deplist, $targets, $deps ) = submit(
            -target => 'data/targ1',
            -sig    => 'data/sig1',
            sub {
                $Decision::Depends::self->{State}
                  ->setSig( 'data/targ1', 'data/sig1', $sig );
            } );

    };
    ok(
        !$@ && eq_hash(
            $deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => [],
                    sig  => ['data/sig1'] } }
        ),
        'different signature on file'
    ) or diag( $@ );
};

#---------------------------------------------------

# force dependency
in_tempdir '' => sub {
    eval {
        mkdir( 'data' );
        mkfile( 'data/sig1', 'contents' );
        touch( 'data/targ1', 'data/sig1' );
        my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

        ( $deplist, $targets, $deps ) = submit(
            -target => 'data/targ1',
            -force  => -sig => 'data/sig1',
            sub {
                $Decision::Depends::self->{State}
                  ->setSig( 'data/targ1', 'data/sig1', $sig );
            } );

    };
    ok(
        !$@ && eq_hash(
            $deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => [],
                    sig  => ['data/sig1'] } }
        ),
        'local force signature dependency'
    ) or diag( $@ );
};

#---------------------------------------------------

# force dependency
in_tempdir '' => sub {
    eval {
        mkdir( 'data' );
        mkfile( 'data/sig1', 'contents' );
        touch( 'data/targ1', 'data/sig1' );
        my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

        ( $deplist, $targets, $deps ) = submit(
            { Force => 1 },
            -target => 'data/targ1',
            -sig    => 'data/sig1',
            sub {
                $Decision::Depends::self->{State}
                  ->setSig( 'data/targ1', 'data/sig1', $sig );
            } );

    };
    ok(
        !$@ && eq_hash(
            $deps,
            {
                'data/targ1' => {
                    var  => [],
                    time => [],
                    sig  => ['data/sig1'] } }
        ),
        'global force signature dependency'
    ) or diag( $@ );

};
#---------------------------------------------------


