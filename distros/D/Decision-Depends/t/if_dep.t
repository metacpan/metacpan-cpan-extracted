#! perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::TempDir::Tiny;

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

#---------------------------------------------------

# no deps, non-existant target, ok return
in_tempdir '' => sub {
    mkdir 'data';
    eval {
        mkdir( 'data' );
        Decision::Depends::Configure( { File => 'data/deps' } );
        if_dep { -target => 'data/targ1' } action { touch( 'data/targ1' ) };
    };
    my $err = $@;
    ok( !$err && -f 'data/targ1',
        'if_dep no deps, non-existant target, ok return' )
      or diag( $err );

};

#---------------------------------------------------

# no deps, non-existant target, sfile, ok return
in_tempdir '' => sub {
    mkdir( 'data' );
    eval {
        Decision::Depends::Configure( { File => 'data/deps' } );
        if_dep { -target => -sfile => 'data/targ1' } action {};
    };
    my $err = $@;
    ok(
        !$err && -f 'data/targ1',
        'if_dep no deps, non-existant target, sfile, ok return',
    ) or diag( $err );

};

#---------------------------------------------------

# no deps, non-existant target, die
in_tempdir '' => sub {

    mkdir( 'data' );
    eval {
        Decision::Depends::Configure( { File => 'data/deps' } );
        if_dep { -target => 'data/targ1' }
          action { die( "ERROR (expected)\n" ) };
    };
    my $err = $@;
    ok(
        $err && $err =~ /^ERROR/ && !-f 'data/targ1',
        'if_dep no deps, non-existant target, die'
    ) or diag( $err );

};

#---------------------------------------------------

# no deps, non-existant target, rethrow
in_tempdir '' => sub {
    mkdir( 'data' );
    eval {
        Decision::Depends::Configure( { File => 'data/deps' } );
        if_dep { -target => 'data/targ1' }
          action { die( "ERROR (expected)\n" ) }
          or die( "rethrow ERROR" );
    };
    my $err = $@;
    ok(
        $err && $@ =~ /^rethrow ERROR/ && !-f 'data/targ1',
        'if_dep no deps, non-existant target, rethrow'
    ) or diag( $err );

};
#---------------------------------------------------

