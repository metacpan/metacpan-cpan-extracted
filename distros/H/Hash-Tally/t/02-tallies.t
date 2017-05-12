use Test::More tests => 1;

use Hash::Tally qw( tally );

my $input1 = {
    Shipping => {
        English => {
             Canada         => 8,
            'United States' => 13,
        },
        French => {
             Canada         => 26,
            'United States' => 3,
        },
    },
    Receiving => {
        English => 56,
        French  => {
             Canada         => 12,
            'United States' => 5,
        },
    },
};

my $output1 = {
    Shipping => {
        English => {
             Canada         => 8,
            'United States' => 13,
             tally          => 21,
        },
        French => {
             Canada         => 26,
            'United States' => 3,
             tally          => 29,
        },
        tally => {
             Canada         => 34,
            'United States' => 16,
             tally          => 50,
        },
    },
    Receiving => {
        English => 56,
        French  => {
             Canada         => 12,
            'United States' => 5,
             tally          => 17,
        },
        tally => 73,
    },
    tally => {
        English => 77,
        French  => {
             Canada         => 38,
            'United States' => 8,
             tally          => 46,
        },
        tally => 123,
    },
};

tally( $input1 );

is_deeply( $input1, $output1, 'tally #1' );
