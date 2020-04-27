# -*- perl -*-

# t/001_basic.t - perform basic tests

use Test::More qw( no_plan );
use strict;
use warnings;
use Scalar::Util ();

BEGIN { use_ok( 'Getopt::Class' ); }

our( $dict, $DEBUG, $VERBOSE, $VERSION, $HELP, $MAN );

require( './t/dictionary.pl' );

{
    local @ARGV = qw( --man );
    my $opt3 = Getopt::Class->new({
        dictionary => $dict,
        debug => 0,
    });
    my $opts3 = $opt3->exec;
    is( $MAN, 'pod2usage man', 'Man code' );
}
