# -*- perl -*-

# t/001_basic.t - perform basic tests

use Test::More qw( no_plan );
use strict;
use warnings;
use Scalar::Util ();

BEGIN { use_ok( 'Getopt::Class' ) || BAIL_OUT( "Unable to load Getopt::Class" ); }

our( $dict, $DEBUG, $VERBOSE, $VERSION, $HELP, $MAN );

require( './t/dictionary.pl' );

# Missing option
{
    local @ARGV = qw();
    my $opt4 = Getopt::Class->new({
        dictionary => $dict,
        debug => 0,
    });
    $opt4->required( [qw( name )] );
    my $opts4 = $opt4->exec;
    my $missing = $opt4->missing;
    is( $missing->[0], 'name', 'Missing check' );
}
