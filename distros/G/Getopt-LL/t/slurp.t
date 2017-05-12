use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );
use FindBin qw($Bin);
use lib 'lib';
use lib 't';
use lib $Bin;
use lib "$Bin/../lib";

our $THIS_TEST_HAS_TESTS = 6;

plan( tests => $THIS_TEST_HAS_TESTS );

@ARGV = qw(The quick -v fox -jumps over -t --lazy=dawg);

use Getopt::LL qw(getoptions);

my $options = getoptions( );

ok( $options, 'getoptions(undef)' );

for my $option (qw(-v -jumps -t)) {
    is( $options->{$option}, 1, $option);
}

is( $options->{'--lazy'}, 'dawg', '--lazy=dawg' );


is_deeply(
    [@ARGV], [qw(The quick fox over)],
'rest is in @ARGV');
