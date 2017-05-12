use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 2;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions);

my $argv = [qw( --head booyahh --bottom )];


my $rules = {
    '--head'        => 'string',
    '--bottom'      => {
        type            => 'string',
        required        => 1,
    },
    '--test'        => {
        type            => 'string',
        default         => 'xyzzy',
    }
            

};

my $getopt_options = {
   die_on_type_mismatch => 0,
   silent               => 1,
   allow_unspecified    => 1,
};

my $result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
like($EVAL_ERROR, qr/Missing required argument: --bottom/,
    'die on missing required argument.'    
);

$argv = [qw( --head booyahh --bottom dingseboms)];
$result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
is ($result->{'--test'}, 'xyzzy', 'default value for arg is set' );
