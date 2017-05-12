#! perl

use strict;
use warnings;

use Test::More;
plan( tests => 5 );

use Test::TempDir::Tiny;

use YAML qw( DumpFile LoadFile );

our $verbose = 0;
our $create  = 0;

use Decision::Depends;

require 't/common.pl';
require 't/depends.pl';

in_tempdir '' => sub {

    mkdir( 'data' );

    #---------------------------------------------------

    # no targets
    eval { submit(); };
    ok( $@ && $@ =~ /no targets/i, 'no targets 1' );

    #---------------------------------------------------

    # valid dependency, but no target
    touch( 'data/dep1' );
    eval { submit( -depend => 'data/dep1' ); };
    my $err = $@;

    ok( $err && $err =~ /no targets/i, 'no targets 2' )
      or diag( $err );

    #---------------------------------------------------

    # should we require dependencies?
    # eval { submit ( 'data/targ1' );};
    # ok( $err && $err =~ /no depend/i, 'no dependencies' )
    #  or diag( $err );

    #---------------------------------------------------
};


{

    my ( $c_deplist, $c_targets, $c_state ) = LoadFile( 'data/traverse' );

    in_tempdir '' => sub {

        mkdir( 'data' );

        touch( 'data/dep1', 'data/dep2' );
        my ( $deplist, $targets ) = submit(
            -target => [ 'targ1', 'targ2' ],
            -target => [ -sfile        => 'targ3' ],
            -target => [ '-slink=dep1' => 'targ4' ],
            -depend => [ 'data/dep1', 'data/dep2' ],
            -var => [ -case => -foobar => 'value' ],
            -sig => 'frank',
        );

        if ( $create ) {
            delete $deplist->{Attr};
            delete $targets->{Attr};
            delete $Decision::Depends::self->{State}{Attr};
            DumpFile( 'data/traverse', $deplist, $targets,
                $Decision::Depends::self->{State} );
        }

        # must rid ourselves of those pesky attributes, as it makes
        # debugging things tough
        delete $deplist->{Attr};
        delete $Decision::Depends::self->{State}{Attr};

        ok( eq_hash( $c_deplist, $deplist ), "Dependency list" );
        ok( eq_array( $c_targets, $targets ), "Targets" );
        ok( eq_hash( $c_state, $Decision::Depends::self->{State} ), "State" );

    };
}
