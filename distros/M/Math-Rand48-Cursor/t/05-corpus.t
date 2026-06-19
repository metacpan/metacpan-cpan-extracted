use strict;
use warnings;
use Test::More;
use Math::BigInt;
use Math::Rand48::Cursor;

# Golden vectors computed by an independent BigInt LCG oracle, frozen as literals
# so the corpus checks the module's arithmetic without relying on the host rand()
# being drand48. Keyed by generator name so a second RNG can slot in alongside
# "drand48".
my $VEC = {
    drand48 => {

        # a = 0x5DEECE66D, c = 0xB, m = 2^48; output is state / 2^48.
        params => { a => '25214903917', c => '11', modulus_bits => 48 },

        # seed => [ X0 (seeded state), X1 (first draw), .. X5 ]. Last two rows
        # match: 2^48-1 reduces to the same 32-bit seed as 4294967295.
        seed_chain => {
            q{0}     => [qw( 13070 48083817484545 211078642492280 27126209522211 245014179504882 162496491130133 )],
            q{1}     => [qw( 78606 11717900325121 127928250295160 234980157041187 94571660010226 159171116698901 )],
            q{2}     => [qw( 144142 256826959876353 44777858098040 161359127849507 225604117226226 155845742267669 )],
            q{3}     => [qw( 209678 220461042716929 243102442611576 87738098657827 75161597731570 152520367836437 )],
            q{12345} => [qw( 809054990 63424337891585 258727032808312 58220636940835 204007354884850 206095737326869 )],
            q{424242} =>
              [qw( 27803136782 23604756893953 173848414872440 202300617337379 97677915480818 151580310211861 )],
            q{987654321} =>
              [qw( 64726913594126 17218460537089 83191068779384 215492891126307 164795510907634 133551400848661 )],
            q{4294967295} =>
              [qw( 281474976658190 84449734643969 12754057978744 100747238713891 113981722288882 165821865561365 )],
            q{281474976710655} =>
              [qw( 281474976658190 84449734643969 12754057978744 100747238713891 113981722288882 165821865561365 )],
        },

        # [ start_state, n, state after seek(n) ].
        seek => [
            [qw( 259974783198072 0 259974783198072 )],
            [qw( 259974783198072 1 194188116896291 )],
            [qw( 259974783198072 2 86691237028594 )],
            [qw( 259974783198072 50 49234262038818 )],
            [qw( 259974783198072 1000 91922728465824 )],
            [qw( 259974783198072 -1 25270525972737 )],
            [qw( 259974783198072 -1000 243620223670864 )],
            [qw( 259974783198072 123456789 81239240480935 )],
            [qw( 259974783198072 -123456789 101437721110109 )],
            [qw( 259974783198072 281474976710656 259974783198072 )],    # seek(2^48) == identity
            [qw( 259974783198072 281474976710657 194188116896291 )],    # seek(2^48 + 1) == seek(1)
        ],

        # States from_rand must recover exactly: bounds, powers of two,
        # alternating bit patterns, the documented example.
        from_rand_states => [
            qw(
              0
              1
              2
              11
              16777216
              140737488355328
              187649984473770
              93824992236885
              259974783198072
              281474976710654
              281474976710655
            )
        ],
    },
};

# generator name -> implementing class; a second RNG registers here.
my %CLASS = ( drand48 => 'Math::Rand48::Cursor' );

for my $gen ( sort keys %$VEC ) {
    my $class = $CLASS{$gen} or do {
        fail "no class registered for generator '$gen'";
        next;
    };
    my $v = $VEC->{$gen};

    subtest "$gen: seed -> state chain (from_seed48 + forward)" => sub {
        for my $seed ( sort keys %{ $v->{seed_chain} } ) {
            my @chain = @{ $v->{seed_chain}{$seed} };
            my $x0    = shift @chain;                   # seeded state; @chain is X1..Xn

            my $rng = $class->from_seed48($seed);
            is $rng->state->bstr, $x0, "from_seed48($seed) lands on X0";

            for my $i ( 0 .. $#chain ) {
                $rng->forward;
                is $rng->state->bstr, $chain[$i], "from_seed48($seed) + forward x@{[ $i + 1 ]} == X@{[ $i + 1 ]}";
            }

            # same target via a single seek() jump
            my $jump = $class->from_seed48($seed)->seek( scalar @chain )->state;
            is $jump->bstr, $chain[-1], "from_seed48($seed)->seek(@{[ scalar @chain ]}) == X@{[ scalar @chain ]}";
        }
    };

    subtest "$gen: seek() jumps" => sub {
        for my $row ( @{ $v->{seek} } ) {
            my ( $start, $n, $want ) = @$row;
            my $got = $class->new( state => $start )->seek($n)->state;
            is $got->bstr, $want, "seek($n) from $start == $want";

            my $neg = Math::BigInt->new($n)->bneg->bstr;
            my $rt  = $class->new( state => $start )->seek($n)->seek($neg)->state;
            is $rt->bstr, $start, "seek($n) then seek($neg) round-trips";
        }
    };

    subtest "$gen: from_rand output -> state inversion" => sub {
        for my $state ( @{ $v->{from_rand_states} } ) {
            my $obs  = $class->new( state => $state )->rand;
            my $back = $class->from_rand($obs)->state;
            is $back->bstr, $state, "from_rand(state/2^48) recovers $state";
        }
    };
}

done_testing;
