#!/usr/bin/perl

# Constructor/connection testing for $transport

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 17;
use File::Remove    ();
use LWP::Online     ();
use JSAN::Transport ();

my $sqlite_index = 'index.sqlite';

BEGIN { File::Remove::remove( \1, 'temp' ) if -e 'temp'; }
END   { File::Remove::remove( \1, 'temp' ) if -e 'temp'; }






#####################################################################
# Tests

#####################################################################
# Sanity

my $transport = JSAN::Transport->new( mirror_local => 'temp' );

ok( $transport, 'JSAN::Transport was successfully instantiated' );
isa_ok( $transport->mirror_location, 'URI::ToDisk' );
ok( $transport->mirror_remote, '->mirror_remote returns true'  );
ok( $transport->mirror_local, '->mirror_local returns true' );
is( $transport->verbose, '', '->verbose is false by default' );



#####################################################################
# Online tests

# Are we online
my $online = LWP::Online::online();

SKIP: {
    skip( "Skipping online tests", 15 ) unless $online;

    # Pull the index as a test
    my $location = $transport->file_location($sqlite_index);
    isa_ok( $location, 'URI::ToDisk' );


    my $qm_sqlindex = quotemeta $sqlite_index;
    ok( $location->uri =~ /$qm_sqlindex$/, '->file_location actually appends filename' );


    my $rv = $transport->file_get($sqlite_index);

    isa_ok( $rv, 'URI::ToDisk' );
    is_deeply( $location, $rv, '->file_get returns URI::ToDisk as expected' );

    ok( -f $rv->path, '->file_get actually gets the file to the expected location' );
    is( $transport->file_get('nosuchfile'), '', "->file_get(nosuchfile) returns ''" );


    # Pull again via mirror
    $rv = $transport->file_mirror($sqlite_index);

    isa_ok( $rv, 'URI::ToDisk' );
    is_deeply( $location, $rv, '->file_mirror returns URI::ToDisk as expected' );

    ok( -f $rv->path, '->file_mirror actually gets the file to the expected location' );
    is( $transport->file_get('nosuchfile'), '', "->file_mirror(nosuchfile) returns ''" );

    # Check the index methods
    ok( $transport->index_file,      '->index_file returns true' );
    ok( -f $transport->index_file,   '->index_file exists'       );
}
