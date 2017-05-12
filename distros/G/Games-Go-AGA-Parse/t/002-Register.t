# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 010-Register.t'

#########################

use strict;
use warnings;

use Carp;
use Test::Exception;
use Test::More tests => 11;

use_ok('Games::Go::AGA::Parse::Register');

my $parser = Games::Go::AGA::Parse::Register->new();
isa_ok ($parser, 'Games::Go::AGA::Parse::Register', 'create object');
my $result;

my @parse_line_tests = (
    ['## TOURNEY Test Tournament ' =>
        {directive  => 'TOURNEY',
         value      => 'Test Tournament'
        },
    ],
    ['# # This is a comment, not a directive ' =>
        {comment    => ' # This is a comment, not a directive'},
    ],
    ["# Comment \n" =>
        {comment    => ' Comment'},
    ],
    ["USA001 P q, A b  2.4\n" =>
        {id         => 'USA1',
         last_name  => 'P q',
         first_name => 'A b',
         rank       => 2.4,
         flags      => [],
         club       => '',
         comment    => '',
         },
    ],
    ['x002 P, A 1d CLub=Foo # cmnt' =>
        {id         => 'X2',
         last_name  => 'P',
         first_name => 'A',
         rank       => '1D',
         flags      => [],
         club       => 'Foo',
         comment    => ' cmnt',
         },
    ],
    ['U00A030   no_first_name 2d # abc  ' =>
        {id         => 'U0A30',
         last_name  => 'no_first_name',
         first_name => '',
         rank       => '2D',
         flags      => [],
         club       => '',
         comment    => ' abc',
         },
    ],
);

foreach my $idx (0 .. $#parse_line_tests) {
    my $test = $parse_line_tests[$idx];
    my $msg = $test->[0];
    chomp $msg;
    is_deeply(scalar $parser->parse($test->[0]), $test->[1], "$idx: $msg");
}

throws_ok {
    my $result = $parser->parse('Xxx, Reid     20d');
} qr/^missing ID or last name before comma/, 'missing ID throws exception';

throws_ok {
    my $result = $parser->parse('T123 Xxx, Reid    # 20d');
} qr/^missing: rank/, 'missing rank throws exception';


SKIP: {

    skip 'because re-throwing an exception fails under Test::More?', 1, unless 0;

    eval {
        $result = $parser->parse('Xxx, Reid     20x Full     -20 4/24/1901 CO');
    };

    if (my $x = Exception::Class->caught('Games::Go::AGA::Parse')) {
        eval {
            Games::Go::AGA::Parse->throw(
                error => $x->error,
                filename => 'foo',
                line  => 321,
            );
        };
        croak "failed to re-throw exception\n";
    }
    if (my $x = Exception::Class->caught('Games::Go::AGA::Parse')) {
        is ($x->full_message,   'xyzzy',   'invalid rank throws exception');
    }
}

__DATA__

# sample register.tde format
## TOURNEY Test Tournament
## RULES ING
#  # HANDICAPS MIN    Bad directive - should be seen as a comment
## ROUNDS 4
#
#   Location:
#       in a galaxy far, far away
#
USA001 Person                      2D
USA002 Person, Another             1d CLUB=AGA # some comment
USA003 People, Some                3k      
XXX004 kind of Person, Some Other  4.44
