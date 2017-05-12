use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 7;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions opt_String opt_Digit opt_Flag);

my $argv = [qw( --foo booyahh --foobar --bar 30 )];


my $rules = {
    '--foo'        => opt_String('The foo option.'),
    '--bar'        => opt_Digit('The bar option.'),
    '--foobar'     => opt_Flag('The foobar option.'),
            

};

my $getopt_options = {
   die_on_type_mismatch => 0,
   silent               => 1,
   allow_unspecified    => 1,
};

my $getopt = Getopt::LL->new($rules, $getopt_options, $argv);
my $result = $getopt->result;
   @ARGV   = @{ $getopt->leftovers };

is_deeply( $result, {
        '--foo'     => 'booyahh',
        '--bar'     => 30,
        '--foobar'  => 1,
    }
);

is_deeply( opt_String('xyzzy'), {
    type    => 'string',
    help    => 'xyzzy',
}, 'opt_String() returns rule spec');

is_deeply( opt_Digit('zyxxy'), {
    type    => 'digit',
    help    => 'zyxxy',
}, 'opt_Digit() returns rule spec');


is_deeply( opt_Flag('yxxyz'), {
    type    => 'flag',
    help    => 'yxxyz',
}, 'opt_Flag() returns rule spec');

can_ok( $getopt, 'help' );

my $help = $getopt->help;
ok( ref $help eq 'HASH', '$getopt->help isa HASH' );


is_deeply( $help, {
        '--foo' => 'The foo option.',
        '--bar' => 'The bar option.',
        '--foobar' => 'The foobar option.',
    },
    'help saved ok.'
);
