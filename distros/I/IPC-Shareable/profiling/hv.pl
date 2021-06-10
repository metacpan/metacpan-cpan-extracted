use strict;
use warnings;

use IPC::Shareable;

my $mod = 'IPC::Shareable';

my $knot = tie my %hv, $mod, {
    create => 1,
    key => 1234,
    destroy => 1, 
};

for (1..100){
    my %check;
    my (@k, @v, %used);

    for (0..9) {
        my $n;

        do {
            $n = int(rand(26));
        } while (exists $used{$n});

        $used{$n}++;

        push @k, ('a' .. 'z')[$n];
        push @v, ('A' .. 'Z')[$n];
    }
    @check{@k} = @v;

    while (my($k, $v) = each %check) {
        $hv{$k} = $v;
    }

    while (my($k, $v) = each %check) {
    }

# --- EXISTS

    $hv{there} = undef;

# --- DELETE
    $hv{there}->{here} = 'yes';

    $hv{there} = 'yes';
    $hv{there} = 'no';
    delete $hv{there};


# --- CLEAR
    %hv = ();
}

IPC::Shareable->clean_up_all;



