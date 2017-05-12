use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 15;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions);

my $argv = [qw( -jumps over -X --the lazy --oops -dawg 10 the -f myfile.txt --quick brown fox)];


my $option_X_is_set = 0;
my $out_to_stdout   = 0;

my $rules = {
    '-jumps!'    => 'string',
    '--the'     => 'string', #{ type => 'string', default => 'monster' },
    '-dawg'     => { type => 'digit', required => 1 },
    '--quick'   => 'flag',
    '--try'     => { type => 'string', default => 'harder' },
    '-X'        => sub {
        $option_X_is_set = 1;
        is( $_[0]->get_prev_arg($_[1]), '-jumps', 'get_prev_arg' );
    },
    '-f'        => sub {
        my ($self, $node) = @_;
        is($self->peek_prev_arg($node), 'the', 'peek_prev_arg');
        my $next = $self->get_next_arg($node);
    
        is($next, 'myfile.txt', 'get_next_arg');
        is($self->peek_next_arg($node), '--quick', 'peek_next_arg');
        if ($next eq '-') {
            $out_to_stdout = 1;
        }

        return $next;
    },

};

my $getopt_options = {
   die_on_type_mismatch => 0,
   silent               => 1,
   allow_unspecified    => 1,
};

my $getopt = Getopt::LL->new($rules, $getopt_options, $argv);
my $result = $getopt->result;
my $rules_ref  = $getopt->rules;
@ARGV = @{ $getopt->leftovers };

is( $rules_ref->{'-jumps'}->{required}, 1, '-jumps is required');

ok( $option_X_is_set,  'option_X_is set. (rule -X => sub { })' );
ok(!$out_to_stdout,    'option -f != -'                        );
is($result->{'-f'},    'myfile.txt',
    '-f = myfile.txt'
);
is($result->{'--the'},  'lazy',
    '--the = lazy'
); 
is($result->{'-dawg'}, 10,
    '-dawg = 10'
);
is($result->{'-jumps'}, 'over',
    '-jumps = over'
);
ok($result->{'--quick'}, '--quick is set');

is( $ARGV[0], 'the' ,  'ARGV[0] == the'  );
is( $ARGV[1], 'brown', 'ARGV[1] == brown');
is( $ARGV[2], 'fox',   'ARGV[2] == fox'  );
