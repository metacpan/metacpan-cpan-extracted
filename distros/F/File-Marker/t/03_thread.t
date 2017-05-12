#!/usr/bin/perl
use strict;
use warnings;
use Config;

BEGIN {
    if ( !$Config{useithreads} ) {
        require Test::More;
        Test::More::plan( skip_all => "Threads not available for this Perl" );
    }
}

use threads;
use Test::More tests => 9;
use File::Spec::Functions;

my $filename = catfile( 't', 'testdata.txt' );
my $expected_line;

SKIP:
{
    skip "File::Marker doesn't support threads on Perl < 5.7.2"
      if $] < 5.007002;

    require_ok("File::Marker");

    my $obj = File::Marker->new($filename);
    isa_ok( $obj, "File::Marker" );

    my $line1 = "one\n";

    is( scalar <$obj>, $line1, "line 1 contents correct" );

    ok( $obj->set_marker("line2"), "marking current position at line 2" );

    ok( $expected_line = <$obj>, "reading line 2" );

    my $thr = threads->new(
        sub {
            ok( $obj->goto_marker("line2"), "jumping back to the marker for line 2" );

            is( scalar <$obj>, $expected_line, "reading line 2 again" );
        }
    );

    # wait for thread to finish
    $thr->join;

    #    # Test counter is off due to the fork
    #    Test::More->builder->current_test( 7 );

    ok( $obj->goto_marker("line2"), "jumping back to the marker for line 2" );

    is( scalar <$obj>, $expected_line, "reading line 2 again" );

}
