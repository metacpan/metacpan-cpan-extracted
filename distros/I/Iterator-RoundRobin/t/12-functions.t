#! /usr/bin/perl

use Test::More tests => 33;

use_ok( 'Iterator::RoundRobin' );

my ($fb);

{
    $fb = Iterator::RoundRobin->new([qw/perl python ruby/], [qw/c c++ c-sharp/]);
    ok($fb, 'Iterator::RoundRobin object created');
    isa_ok($fb, 'Iterator::RoundRobin', 'Iterator::RoundRobin object created');
}

{
    # Test even lists
    my $fb = Iterator::RoundRobin->new(
        [qw/usera-1 usera-2 usera-3 usera-4/],
        [qw/userb-1 userb-2 userb-3 userb-4/],
    );
    my @list = qw/usera-1 userb-1 usera-2 userb-2 usera-3 userb-3 usera-4 userb-4/;
    my $cnt = 0;
    while (my $tmp = $fb->next()) {
        is($tmp, $list[$cnt], "Set 1 iterator place $cnt match.");
        $cnt++;
    }
}

{
    # Test even lists
    my $fb = Iterator::RoundRobin->new(
        [qw/usera-1 usera-2/],
        [qw/userb-1 userb-2/],
        [qw/userc-1 userc-2/],
    );
    my @list = qw/usera-1 userb-1 userc-1 usera-2 userb-2 userc-2/;
    my $cnt = 0;
    while (my $tmp = $fb->next()) {
        is($tmp, $list[$cnt], "Set 2 iterator place $cnt match.");
        $cnt++;
    }
}

{
    # Test uneven lists
    my $fb = Iterator::RoundRobin->new(
        [qw/usera-1 usera-2 usera-3/],
        [qw/userb-1 userb-2 userb-3 userb-4/],
    );
    my @list = qw/usera-1 userb-1 usera-2 userb-2 usera-3 userb-3 userb-4/;
    my $cnt = 0;
    while (my $tmp = $fb->next()) {
        is($tmp, $list[$cnt], "Set 3 iterator place $cnt match.");
        $cnt++;
    }
}

{
    # Test uneven lists
    my $fb = Iterator::RoundRobin->new(
        [qw/usera-1 usera-2 usera-3/],
        [qw/userb-1 userb-2 userb-3 userb-4/],
        [qw/userc-1 userc-2/],
    );
    my @list = qw/usera-1 userb-1 userc-1 usera-2 userb-2 userc-2 usera-3 userb-3 userb-4/;
    my $cnt = 0;
    while (my $tmp = $fb->next()) {
        is($tmp, $list[$cnt], "Set 4 iterator place $cnt match.");
        $cnt++;
    }
}


