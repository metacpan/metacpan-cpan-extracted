#!/usr/bin/perl

# Top level testing for JSAN::Client itself

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use Scalar::Util ();
use File::Remove 'remove';
use LWP::Online  'online';

BEGIN { remove( \1, 'temp' ) if -e 'temp'; }
END   { remove( \1, 'temp' ) if -e 'temp'; }

use JSAN::Client {
    mirror_local => 'temp', 
    prune => 1 
};

# Create and/or clear the test directory
my $testdir = catdir( curdir(), '07_static_files' );
remove \1, $testdir if -e $testdir;
ok( ! -e $testdir, "Test directory '$testdir' does not exist" );
ok( mkdir($testdir), "Create test directory '$testdir'" );
END {
    remove \1, $testdir if -e $testdir;
}

ok( defined &Scalar::Util::blessed, 'Scalar::Util has blessed function' );





#####################################################################
# Test constructor and accessors

my $Client = JSAN::Client->new(
    prefix  => $testdir,
    verbose => 0,
);


#####################################################################
# Install a known library

SKIP: {
    skip( "Skipping online tests", 3 ) unless online();

    is( $Client->install_library('OpenJSAN.Test.StaticFiles'), 1, '->install_library for distribution with static files' );
    
    my @requires = map { catfile(@$_) } (
        [ qw(OpenJSAN Test StaticFiles.js) ],
        [ qw(OpenJSAN Test StaticFiles assets all.css) ],
    );
    
    foreach my $file ( @requires ) {
        my $path = catfile( $testdir, $file );
        ok( -f $path, "Library file '$file' was installed where expected" );
    }
}

exit(0);
