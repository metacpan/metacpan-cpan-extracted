# -*- perl -*-

# t/001_basic.t - perform basic tests

use Test::More qw( no_plan );
use strict;
use warnings;
use Scalar::Util ();

BEGIN { use_ok( 'Getopt::Class' ) || BAIL_OUT( "Unable to load Getopt::Class" ); }

our( $dict, $DEBUG, $VERBOSE, $VERSION, $HELP, $MAN );

require( './t/dictionary.pl' );

{
    local @ARGV = qw( --help );
    my $opt2 = Getopt::Class->new({
        dictionary => $dict,
        debug => 0,
    });
    my $opts2 = $opt2->exec;
    is( $HELP, 'pod2usage help', 'Help code' );
}

