use warnings;
use strict;

use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process);
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');


my $have_xs = $IPC::Shareable::_have_xs;

note $have_xs
    ? "XS _is_child path is ENABLED"
    : "XS _is_child path is DISABLED — testing pure Perl only";

# ── XS function existence ────────────────────────────────────────────────
SKIP: {
    skip 'XS not compiled on this system', 1 unless $have_xs;
    ok defined(&IPC::Shareable::_is_child_xs),
        'XS _is_child_xs function is defined';
}

# ── Untied refs: both paths return undef ─────────────────────────────────
{
    local $IPC::Shareable::_have_xs = 0;

    is IPC::Shareable::_is_child(undef),       undef, 'PP: undef -> undef';
    is IPC::Shareable::_is_child("string"),    undef, 'PP: string -> undef';
    is IPC::Shareable::_is_child(42),          undef, 'PP: integer -> undef';
    is IPC::Shareable::_is_child({}),          undef, 'PP: untied hashref -> undef';
    is IPC::Shareable::_is_child([]),          undef, 'PP: untied arrayref -> undef';
    is IPC::Shareable::_is_child(\my $x),      undef, 'PP: untied scalarref -> undef';
    is IPC::Shareable::_is_child(sub { 1 }),   undef, 'PP: coderef -> undef';
}

SKIP: {
    skip 'XS not available', 7 unless $have_xs;

    is IPC::Shareable::_is_child(undef),       undef, 'XS: undef -> undef';
    is IPC::Shareable::_is_child("string"),    undef, 'XS: string -> undef';
    is IPC::Shareable::_is_child(42),          undef, 'XS: integer -> undef';
    is IPC::Shareable::_is_child({}),          undef, 'XS: untied hashref -> undef';
    is IPC::Shareable::_is_child([]),          undef, 'XS: untied arrayref -> undef';
    is IPC::Shareable::_is_child(\my $y),      undef, 'XS: untied scalarref -> undef';
    is IPC::Shareable::_is_child(sub { 1 }),   undef, 'XS: coderef -> undef';
}

# ── Tied refs: test each type independently in its own scope ─────────────
{
    my %h;
    my $knot_h = tie %h, 'IPC::Shareable', {
        create => 1, destroy => 1, serializer => 'storable'
    };
    my $href = \%h;

    # PP path
    {
        local $IPC::Shareable::_have_xs = 0;
        my $r = IPC::Shareable::_is_child($href);
        isa_ok $r, 'IPC::Shareable', 'PP: tied hashref -> knot object';
        is $r, $knot_h, 'PP: tied hashref returns the correct knot';
    }

    # XS path
    SKIP: {
        skip 'XS not available', 2 unless $have_xs;
        my $r = IPC::Shareable::_is_child($href);
        isa_ok $r, 'IPC::Shareable', 'XS: tied hashref -> knot object';
        is $r, $knot_h, 'XS: tied hashref returns the correct knot';
    }

    IPC::Shareable->clean_up;
}

{
    my @a;
    my $knot_a = tie @a, 'IPC::Shareable', {
        create => 1, destroy => 1, serializer => 'storable'
    };
    my $aref = \@a;

    {
        local $IPC::Shareable::_have_xs = 0;
        my $r = IPC::Shareable::_is_child($aref);
        isa_ok $r, 'IPC::Shareable', 'PP: tied arrayref -> knot object';
        is $r, $knot_a, 'PP: tied arrayref returns the correct knot';
    }

    SKIP: {
        skip 'XS not available', 2 unless $have_xs;
        my $r = IPC::Shareable::_is_child($aref);
        isa_ok $r, 'IPC::Shareable', 'XS: tied arrayref -> knot object';
        is $r, $knot_a, 'XS: tied arrayref returns the correct knot';
    }

    IPC::Shareable->clean_up;
}

{
    my $s;
    my $knot_s = tie $s, 'IPC::Shareable', {
        create => 1, destroy => 1, serializer => 'storable'
    };
    my $sref = \$s;

    {
        local $IPC::Shareable::_have_xs = 0;
        my $r = IPC::Shareable::_is_child($sref);
        isa_ok $r, 'IPC::Shareable', 'PP: tied scalarref -> knot object';
        is $r, $knot_s, 'PP: tied scalarref returns the correct knot';
    }

    SKIP: {
        skip 'XS not available', 2 unless $have_xs;
        my $r = IPC::Shareable::_is_child($sref);
        isa_ok $r, 'IPC::Shareable', 'XS: tied scalarref -> knot object';
        is $r, $knot_s, 'XS: tied scalarref returns the correct knot';
    }

    IPC::Shareable->clean_up;
}

# ── Simulate no-compiler: test full tie/STORE/FETCH/lock/unlock under PP ─
{
    local $IPC::Shareable::_have_xs = 0;

    my %nc_h;
    my $nc_knot = tie %nc_h, 'IPC::Shareable', {
        create => 1, destroy => 1, serializer => 'storable'
    };
    ok tied(%nc_h), 'no-compiler simulation: tie succeeds under pure Perl';

    $nc_h{foo} = 'bar';
    is $nc_h{foo}, 'bar', 'no-compiler simulation: FETCH works';

    $nc_h{child} = { a => 1, b => 2 };
    is_deeply $nc_h{child}, { a => 1, b => 2 },
        'no-compiler simulation: nested hash round-trips';

    my $child_ref = IPC::Shareable::_is_child($nc_h{child});
    isa_ok $child_ref, 'IPC::Shareable',
        'no-compiler simulation: _is_child detects nested shareable';

    tied(%nc_h)->lock;
    $nc_h{foo} = 'locked_write';
    is $nc_h{foo}, 'locked_write', 'no-compiler simulation: locked write';
    tied(%nc_h)->unlock;

    IPC::Shareable->clean_up;
}

# ── Cleanup ──────────────────────────────────────────────────────────────
IPC::Shareable->clean_up_all;
IPC::Shareable::_end;

assert_clean_process();

done_testing;
