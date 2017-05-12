use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 13;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );

@ARGV = qw( The --quick 10 brown fox -jumps over --the lazy -dawg );

use Getopt::LL::Short qw(getoptions);

my $options = Getopt::LL::Short::getoptions([
    '--quick=d',
    '-jumps=s',
    '--the=s',
    '-dawg',
]);


is( $options->{'--quick'}, 10,     '--quick = 10'   );
is( $options->{'-jumps'},  'over', '-jumps  = over' );
is( $options->{'--the'},   'lazy', '--the  = lazy'  );
is( $options->{'-dawg'},   1,      '-dawg  = 1'     );

is( $ARGV[0], 'The',      'rest[0] == The'    );
is( $ARGV[1], 'brown',    'rest[1] == brown'  );
is( $ARGV[2], 'fox',      'rest[2] == fox'    );

@ARGV = qw( The --quick 10 brown fox -jumps over --the lazy -dawg );
my $default = getoptions( );
ok( $default, 'getoptions() without rules' );

is($default->{'--quick'}, 1, 'default ruletype for --quick is flag');
is($default->{'-jumps'}, 1, 'default ruletype for --jumps is flag');
is($default->{'--the'}, 1, 'default ruletype for --the is flag');
is($default->{'-dawg'}, 1, 'default ruletype for -dawg is flag');

is_deeply([@ARGV], [qw(The 10 brown fox over lazy)],
    'the rest is kept in @ARGV'
);
