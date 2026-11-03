use 5.020;
use strict;
use warnings;
use Test::More;
use Devel::XSCover::DB ();

my $a = { object => 'Spike.gcda', files => {
    'include/spike.h' => {
        lines     => { 4 => 1, 6 => 1, 7 => 1, 8 => 1 },
        functions => [ { name => 'spike_square', line => 4, count => 1 } ],
        blocks    => [ { line => 6, arms => [0, 1] } ],
    },
    'Spike.xs' => { lines => { 27 => 2 }, functions => [], blocks => [ { line => 36, arms => [2, 1] }, { line => 36, arms => [1, 1] } ] },
}, generated => { 'Spike.c' => { lines => {}, functions => [ { name => 'XS_Spike_add', line => 178, count => 2 } ], blocks => [] } } };
my $b = { object => 'src/helper.gcda', files => {
    'include/spike.h' => {
        lines     => { 4 => 1, 6 => 1, 7 => 0, 8 => 1, 11 => 1, 13 => 1 },
        functions => [ { name => 'spike_square', line => 4, count => 1 }, { name => 'spike_only_helper', line => 11, count => 1 } ],
        blocks    => [ { line => 6, arms => [1, 0] } ],
    },
    'src/helper.c' => { lines => { 5 => 3 }, functions => [ { name => 'spike_helper_switch', line => 3, count => 3 } ], blocks => [ { line => 5, arms => [1, 1, 1, 0] } ] },
}, generated => {} };

my ($files, $generated) = Devel::XSCover::DB->new(silent => 1)->merge($a, $b);
is_deeply([sort keys %$files], ['Spike.xs', 'include/spike.h', 'src/helper.c'], 'three files from two objects');
my $h = $files->{'include/spike.h'};
is_deeply($h->{lines}, { 4 => 2, 6 => 2, 7 => 1, 8 => 2, 11 => 1, 13 => 1 }, 'the union of lines, counts summed');
is_deeply($h->{functions}, [ { name => 'spike_square', line => 4, count => 2 }, { name => 'spike_only_helper', line => 11, count => 1 } ], 'functions summed by name and line');
is_deeply($h->{blocks}, [ { line => 6, arms => [1, 1] } ], 'the same block from both objects, arms summed');
is_deeply($files->{'Spike.xs'}{blocks}, [ { line => 36, arms => [2, 1] }, { line => 36, arms => [1, 1] } ], 'two blocks on one line stay two');
is_deeply($generated->{'Spike.c'}{functions}, [ { name => 'XS_Spike_add', line => 178, count => 2 } ], 'the generated c carried over');
is_deeply($a->{files}{'include/spike.h'}{blocks}, [ { line => 6, arms => [0, 1] } ], 'the input is untouched');

done_testing;
