use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 17;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions);

my $argv = [qw( --jumps over -X --the lazy -dawg 10 the -f myfile.txt -- --quick brown -fox)];

print '__ARGV__[]: ', join(q{ }, map { "[$_]" } @{ $argv }), "\n";


my $option_X_is_set = 0;
my $out_to_stdout   = 0;

my $rules = {
    '--jumps'    => 'string',
    '--the'     => 'string', #{ type => 'string', default => 'monster' },
    '-d'     => 'flag',
    '-a'     => 'flag',
    '-w'     => 'flag',
    '-g'     => 'digit',
    '--quick'   => 'flag',
    '--try'     => { type => 'string', default => 'harder' },
    '-X'        => sub {
        $option_X_is_set = 1;
        is( $_[0]->get_prev_arg($_[1]), '--jumps', 'get_prev_arg' );
    },
    '-f'        => sub {
        my ($self, $node) = @_;
        is($self->peek_prev_arg($node), 'the', 'peek_prev_arg');
        my $next = $self->get_next_arg($node);
    
        is($next, 'myfile.txt', 'get_next_arg');
        is($self->peek_next_arg($node), '--', 'peek_next_arg');
        if ($next eq '-') {
            $out_to_stdout = 1;
        }

        return $next;
    }
            

};

my $getopt_options = {
   die_on_type_mismatch => 0,
   silent               => 1,
   style                => 'GNU',
   allow_unspecified    => 1,
};

my $result = getoptions($rules, $getopt_options, $argv);

ok( $option_X_is_set,  'option_X_is set. (rule -X => sub { })' );
ok(!$out_to_stdout,    'option -f != -'                        );
is($result->{'-f'},    'myfile.txt',
    '-f = myfile.txt'
);
is($result->{'--the'},  'lazy',
    '--the = lazy'
); 
is($result->{'-d'}, 1,
    '-d = 1'
);
is($result->{'-a'}, 1,
    '-a = 1'
);
is($result->{'-w'}, 1,
    '-w = 1'
);
is($result->{'-g'}, 10,
    '-g = 10'
);
is($result->{'--jumps'}, 'over',
    '--jumps = over'
);

is( $ARGV[0], 'the' ,  'ARGV[0] == the'  );
is( $ARGV[1], '--quick', 'ARGV[1] == --quick');
is( $ARGV[2], 'brown',   'ARGV[2] == brown'  );
is( $ARGV[3], '-fox',   'ARGV[2] == -fox'  );
