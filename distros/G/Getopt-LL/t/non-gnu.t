use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 13;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );

eval 'use IO::Capture::Stderr';
my $has_capture = !$EVAL_ERROR;
if ($has_capture) {
    require IO::Capture::Stderr;
    my $cserr = IO::Capture::Stderr->new();
    $cserr->start();
}


use Getopt::LL qw(getoptions);

my $argv = [qw( --jumps=over -X --the lazy --rye=badabing -dawg 10 - the -f
myfile.txt -- --quick brown fox -klaus)];

print '__ARGV__[]: ', join(q{ }, map { "[$_]" } @{ $argv }), "\n";


my $option_X_is_set = 0;
my $out_to_stdout   = 0;

my $rules = {
    '--jumps'    => 'string',
    '--the'     => 'string', #{ type => 'string', default => 'monster' },
    '-dawg'     => 'digit',
    '--quick'   => 'flag',
    '--try(harder)' => 'string',
    '--rye'     => { type => 'string', default => 'softer' },
    '-klaus'    => 'digit',
    '-X'        => sub {
        $option_X_is_set = 1;
        is( $_[0]->get_prev_arg($_[1]), '--jumps=over', 'get_prev_arg' );
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
   style                => 'default',
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
is($result->{'-dawg'}, 10,
    '-dawg = 10'
);
is($result->{'--jumps'}, 'over',
    '--jumps = over'
);
is($result->{'--rye'}, 'badabing');
is($result->{'--try'}, 'harder');
eval 'use YAML; print YAML::Dump(\@ARGV), "\n";';
is_deeply([@ARGV],
    [qw( - the -- brown fox)],
    '@ARGV is - the -- brown fox'
);

