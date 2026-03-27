use strict;
use warnings;
use Test::More;
use Loo;

# ── Freezer callback ─────────────────────────────────────────────
{
    package My::Freeze;
    sub new  { bless { val => $_[1] }, $_[0] }
    sub freeze { $_[0]->{frozen} = 1 }
}

{
    my $obj = My::Freeze->new(42);
    ok(!$obj->{frozen}, 'not frozen before dump');

    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Freezer('freeze');
    my $out = $dd->Dump;
    ok($obj->{frozen}, 'freezer callback was invoked');
    like($out, qr/'My::Freeze'/, 'frozen object dumped with class');
    like($out, qr/'frozen' => 1|'val' => 42/, 'frozen object has fields');
}

# ── Freezer with empty string (disabled) ─────────────────────────
{
    package My::Freeze2;
    our $called = 0;
    sub new  { bless {}, $_[0] }
    sub freeze { $called = 1 }
}

{
    my $obj = My::Freeze2->new;
    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Freezer('');
    $dd->Dump;
    is($My::Freeze2::called, 0, 'empty freezer: callback not invoked');
}

# ── Toaster callback ─────────────────────────────────────────────
{
    my $obj = bless { x => 1 }, 'My::Toast';
    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Toaster('revive');
    my $out = $dd->Dump;
    like($out, qr/->revive\(\)/, 'toaster: ->revive() appended');
}

# ── Toaster with empty string (disabled) ─────────────────────────
{
    my $obj = bless { x => 1 }, 'My::Toast2';
    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Toaster('');
    my $out = $dd->Dump;
    unlike($out, qr/->/, 'empty toaster: no method call appended');
}

# ── Freezer + Toaster together ────────────────────────────────────
{
    package My::Both;
    sub new    { bless { v => $_[1] }, $_[0] }
    sub freeze { $_[0]->{frozen} = 1 }
}

{
    my $obj = My::Both->new(7);
    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Freezer('freeze')->Toaster('thaw')->Sortkeys(1);
    my $out = $dd->Dump;
    ok($obj->{frozen}, 'both: freezer called');
    like($out, qr/->thaw\(\)/, 'both: toaster appended');
}

done_testing;
