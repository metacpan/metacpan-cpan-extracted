use warnings;
use strict;

use Test::More;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

{
    # STORE croaks when _encode() returns undef (no lock held)

    tie my $sv => 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };

    {
        # Override _encode via local typeglob, not Mock::Sub: Mock::Sub 1.08
        # (on some CPAN testers) returns the call args for return_value => undef,
        # so the croak-on-undef path never fired. Bare `return` = failure in any
        # context; no warnings 'redefine' is block-scoped so real redefines warn.
        no warnings 'redefine';
        local *IPC::Shareable::_encode = sub { return };

        is
            eval { $sv = 'foo'; 1 },
            undef,
            "STORE croaks when _encode() returns undef";

        like
            $@,
            qr/Could not write to shared memory/,
            "...and the error message is correct";
    }
}

{
    # CLEAR croaks when _encode() returns undef (no lock held)

    my $s = tie my %hv => 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };
    $hv{a} = 1;

    {
        # Override _encode via local typeglob, not Mock::Sub: Mock::Sub 1.08
        # (on some CPAN testers) returns the call args for return_value => undef,
        # so the croak-on-undef path never fired. Bare `return` = failure in any
        # context; no warnings 'redefine' is block-scoped so real redefines warn.
        no warnings 'redefine';
        local *IPC::Shareable::_encode = sub { return };

        is
            eval { %hv = (); 1 },
            undef,
            "CLEAR croaks when _encode() returns undef";

        like
            $@,
            qr/Could not write to shared memory/,
            "...and the CLEAR error message is correct";
    }
}

{
    # DELETE croaks when _encode() returns undef (no lock held)

    tie my %hv => 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };
    $hv{a} = 1;

    {
        # Override _encode via local typeglob, not Mock::Sub: Mock::Sub 1.08
        # (on some CPAN testers) returns the call args for return_value => undef,
        # so the croak-on-undef path never fired. Bare `return` = failure in any
        # context; no warnings 'redefine' is block-scoped so real redefines warn.
        no warnings 'redefine';
        local *IPC::Shareable::_encode = sub { return };

        is
            eval { delete $hv{a}; 1 },
            undef,
            "DELETE croaks when _encode() returns undef";

        like
            $@,
            qr/Could not write to shared memory/,
            "...and the DELETE error message is correct";
    }
}

for my $op (
    [ 'PUSH',      sub { my $a = shift; push @$a, 'x'       } ],
    [ 'POP',       sub { my $a = shift; pop @$a              } ],
    [ 'SHIFT',     sub { my $a = shift; shift @$a            } ],
    [ 'UNSHIFT',   sub { my $a = shift; unshift @$a, 'x'     } ],
    [ 'SPLICE',    sub { my $a = shift; splice @$a, 0, 1     } ],
    [ 'STORESIZE', sub { my $a = shift; $#$a = 2             } ],
) {
    my ($name, $code) = @$op;

    tie my @av => 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };
    @av = (1, 2, 3);

    {
        # Override _encode via local typeglob, not Mock::Sub: Mock::Sub 1.08
        # (on some CPAN testers) returns the call args for return_value => undef,
        # so the croak-on-undef path never fired. Bare `return` = failure in any
        # context; no warnings 'redefine' is block-scoped so real redefines warn.
        no warnings 'redefine';
        local *IPC::Shareable::_encode = sub { return };

        is
            eval { $code->(\@av); 1 },
            undef,
            "$name croaks when _encode() returns undef";

        like
            $@,
            qr/Could not write to shared memory/,
            "...$name error message is correct";
    }
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
