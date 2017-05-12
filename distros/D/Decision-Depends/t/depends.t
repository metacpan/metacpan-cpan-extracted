#! perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::TempDir::Tiny;

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

my $err;

our ( $deplist, $targets, $deps );

#---------------------------------------------------

in_tempdir '' => sub {

    mkdir 'data';

    eval {
        touch( 'data/targ1', 'data/dep1', 'data/dep2' );
        mkfile( 'data/sig1', 'contents' );
        my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

        ( $deplist, $targets, $deps ) = submit(
            -target => [
                -sfile              => 'data/sfile',
                '-slink=data/targ1' => 'data/slink',
                'data/targ1',
            ],
            -time => [ 'data/dep1', 'data/dep2' ],
            -var => [ -case => -foobar => 'va2lue' ],
            -sig => 'data/sig1',
        );
    };
    $err = $@;
    ok(
        !$@
          && eq_hash(
            $deps,
            {
                'data/slink' => {
                    'var'  => [],
                    'sig'  => [],
                    'time' => []
                },
                'data/targ1' => {
                    'var'  => ['foobar'],
                    'sig'  => ['data/sig1'],
                    'time' => [ 'data/dep1', 'data/dep2' ]
                },
                'data/sfile' => {
                    'var'  => [],
                    'sig'  => [],
                    'time' => [] } }
          ),

        'lots of stuff'
    ) or diag( $err );


};

#---------------------------------------------------

# ensure that we're reading in the dependency file correctly

in_tempdir '' => sub {

    mkdir 'data';

    my $cnt = 0;
    eval {
        $Decision::Depends::self->{State}->EraseState;
        Decision::Depends::Configure( { File => 'data/deps' } );

        if_dep { 'data/targ1', -var => ( -foo => 'val' ) } action {
            touch( 'data/targ1' );
        };

        $Decision::Depends::self->{State}->EraseState;
        Decision::Depends::Configure( { File => 'data/deps' } );

        if_dep { 'data/targ1', -var => ( -foo => 'val' ) } action {
            $cnt++;
        };
    };
    $err = $@;
    ok( !$@ && $cnt == 0, 'dependency file reread correctly (1)' )
      or diag( $err );

    eval {
        $Decision::Depends::self->{State}->EraseState;
        Decision::Depends::Configure( { File => 'data/deps' } );

        if_dep { 'data/targ1', -var => ( -foo => 'val1' ) } action {
            $cnt++;
        };
    };
    $err = $@;
    ok( !$@ && $cnt == 1, 'dependency file reread correctly (2)' )
      or diag( $err );


};

#---------------------------------------------------
