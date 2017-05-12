use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 5;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions);

my $argv = [qw( --head booyahh --bottom )];


my $rules = {
    '--head'        => sub {
        my ($self, $node) = @_;
        is($self->peek_next_arg($node),  'booyahh', 'peek next arg from head');
        ok(!$self->peek_prev_arg($node), 'cannot peek previous in head node');
        ok(!$self->get_prev_arg($node),  'cannot get previous in head node');
    },
    '--bottom'        => sub {
        my ($self, $node) = @_;
        ok(!$self->peek_next_arg($node), 'cannot peek next in bottom node');
        ok(!$self->get_next_arg($node),  'cannot get next in bottom node');
    }
            

};

my $getopt_options = {
   die_on_type_mismatch => 0,
   silent               => 1,
   allow_unspecified    => 1,
};

my $result = getoptions($rules, $getopt_options, $argv);
