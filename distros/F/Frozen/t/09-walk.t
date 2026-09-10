#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();

# Every leaf exactly once, with the right path, over every shape the format
# holds. The count is compared against a pure-Perl walk of the original, so
# the assertion is against an independent answer rather than against the
# walker's own arithmetic.

my $data = {
    top    => 'a',
    hash   => { x => 1, y => { z => 2 } },
    array  => [ 10, 20, [ 30, 31 ] ],
    hia    => [ { k => 'v' }, { k2 => 'v2' } ],   # hash inside array
    aih    => { list => [ 'p', 'q' ] },           # array inside hash
    empty_h => {},
    empty_a => [],
    undefd  => undef,
    deep    => { a => { b => { c => { d => 'bottom' } } } },
};

sub perl_leaves {
    my ($d, $pre, $out) = @_;
    $out ||= [];
    if (ref $d eq 'HASH') {
        if (!keys %$d) { return $out }          # an empty branch has no leaves
        perl_leaves($d->{$_}, defined $pre ? "$pre.$_" : $_, $out) for sort keys %$d;
    }
    elsif (ref $d eq 'ARRAY') {
        if (!@$d) { return $out }
        perl_leaves($d->[$_], defined $pre ? "$pre.$_" : $_, $out) for 0 .. $#$d;
    }
    else { push @$out, $pre }
    return $out;
}

my $expect = perl_leaves($data);
my $fz     = Frozen->attach(Frozen->freeze($data));

my (@paths, @segs);
my $n = $fz->each_leaf(sub { push @paths, $_[0]; push @segs, $_[2] });

is($n, scalar @$expect,
   "each_leaf visited $n leaves, the same count a pure-Perl walk finds");
is_deeply([sort @paths], [sort @$expect],
          'and exactly the same paths');

# The segments are the authoritative form; the joined path is a convenience.
is(scalar @segs, $n, 'every leaf carried its segments');
my $bad = grep { join('.', @{ $segs[$_] }) ne $paths[$_] } 0 .. $#segs;
is($bad, 0, 'and joining the segments reproduces the path');

# Empty containers contribute no leaves, and are not miscounted as one.
ok(!grep({ /^empty_[ha]/ } @paths), 'an empty hash or array yields no leaf');

# Depth.
ok(scalar(grep { $_ eq 'deep.a.b.c.d' } @paths), 'four levels deep is reached');

# A separator other than the default.
{
    my @p;
    $fz->each_leaf(sub { push @p, $_[0] }, '/');
    ok(scalar(grep { $_ eq 'deep/a/b/c/d' } @p),
       'and the separator is settable');
}

# Every handed-back handle really is a leaf handle.
{
    my @kinds;
    $fz->each_leaf(sub { push @kinds, $fz->kind($_[1]) });
    my %k = map { $_ => 1 } @kinds;
    ok(!$k{hash} && !$k{array},
       'no branch is reported as a leaf') or diag join ',', sort keys %k;
}

done_testing;
