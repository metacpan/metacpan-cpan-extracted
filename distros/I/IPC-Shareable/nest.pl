use strict;
use warnings;

use IPC::Shareable;

my $mod = 'IPC::Shareable';

my $knot = tie my %hv, $mod, {
    create => 1,
    key => 1234,
    destroy => 1,
#    persist => 1
};

for my $alpha ('a'..'z') {
    for my $num (0..1000) {
        $hv{$alpha}->{$num} = $alpha;
        my $thing = $hv{$alpha}->{num};
        delete $hv{$alpha};
    }
}

IPC::Shareable->clean_up_all;



