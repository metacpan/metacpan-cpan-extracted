# -*- perl -*-

# t/001_basic.t - perform basic tests

use Test::More qw( no_plan );
use strict;
use warnings;
use Scalar::Util ();

BEGIN { use_ok( 'Getopt::Class' ); }

our( $dict, $DEBUG, $VERBOSE, $VERSION, $HELP, $MAN );

require( './t/dictionary.pl' );

# Wrong patter for language
{
    # diag( "\@ARGV value is '" . join( "', '", @ARGV ) . "'." );
    local @ARGV = qw( --langs FR );
    # diag( "\@ARGV value now is '" . join( "', '", @ARGV ) . "'." );
    my $opt5 = Getopt::Class->new({
        dictionary => $dict,
        debug => 0,
    });
    my $opts5 = $opt5->exec;
    my $err = $opt5->check_class_data( 'person' );
    is( exists( $err->{regexp}->{langs} ), 1, 'Data regular expression check' );
}

