#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Hash::Fold qw(fold unfold);
use Storable qw(dclone);
use Test::More tests => 54;

sub folds_ok {
    my $hash = shift;
    my $want = shift;
    my $options = @_ == 1 ? shift : { @_ };

    local (
        $Data::Dumper::Terse,
        $Data::Dumper::Indent,
        $Data::Dumper::Sortkeys
    ) = (1, 1, 1);

    # report errors with the caller's line number
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $got;

    eval {
        $got = fold($hash, $options);

        unless (is_deeply($got, $want)) {
            warn 'got: ', Dumper($got), $/;
            warn 'want: ', Dumper($want), $/;
        }

        isnt $got, $want, 'different refs';

        is_deeply unfold($got, $options),
            $hash,
            'roundtrip: unfold(fold(hash)) == hash';
    };

    ok !$@, 'no exception raised' or diag "Exception: $@";

    return $got;
}

# exercise a bit of everything to make sure the basics work
{
    my $object = bless {};
    my $regex  = qr{whatever};
    my $glob   = \*STDIN;

    my $hash = {
        foo => {
            bar => {
                string => 'Hello, world!',
                number => 42,
                regex  => $regex,
                glob   => $glob,
                array  => [ 'one', 'two', { three => 'four', five => { six => 'seven' } }, [ 'eight', ['nine'] ] ],
                object => $object,
            }
        },
        baz => 'quux',
    };

    my $want = {
        'baz'                      => 'quux',
        'foo.bar.array.0'          => 'one',
        'foo.bar.array.1'          => 'two',
        'foo.bar.array.2.five.six' => 'seven',
        'foo.bar.array.2.three'    => 'four',
        'foo.bar.array.3.0'        => 'eight',
        'foo.bar.array.3.1.0'      => 'nine',
        'foo.bar.glob'             => $glob,
        'foo.bar.number'           => 42,
        'foo.bar.object'           => $object,
        'foo.bar.regex'            => $regex,
        'foo.bar.string'           => 'Hello, world!'
    };

    folds_ok $hash => $want;
}

# seeing a value more than once is not the same thing as seeing a value inside
# itself (circular reference). make sure the former doesn't trigger the callback
# associated with the latter
{
    my $seen   = 0;
    my $on_cycle = sub { $seen = 1 };
    my $object = bless {};

    my $hash = {
        a => { b => $object },
        c => { d => $object },
    };

    my $want = {
        'a.b' => $object,
        'c.d' => $object,
    };

    folds_ok $hash => $want, on_cycle => $on_cycle;
    is $seen, 0;
}

# on_cycle: trigger the circular reference callback (hashref)
{
    my @seen;
    my $on_cycle = sub { isa_ok $_[0], 'Hash::Fold'; push @seen, $_[1] };
    my $circular = { self => undef };

    $circular->{self} = $circular;

    my $hash = {
        a => { b => $circular },
        c => { d => $circular },
    };

    my $want = {
        'a.b.self' => $circular,
        'c.d.self' => $circular,
    };

    folds_ok $hash => $want, on_cycle => $on_cycle;
    is_deeply \@seen, [ $circular, $circular ];
    is $seen[0], $circular; # same ref
    is $seen[1], $circular; # same ref
}

# on_cycle: trigger the circular reference callback (arrayref)
{
    my @seen;
    my $on_cycle = sub { isa_ok $_[0], 'Hash::Fold'; push @seen, $_[1] };
    my $circular = [ undef ];

    $circular->[0] = $circular;

    my $hash = {
        a => { b => $circular },
        c => { d => $circular },
    };

    my $want = {
        'a.b.0' => $circular,
        'c.d.0' => $circular,
    };

    folds_ok $hash => $want, on_cycle => $on_cycle;
    is_deeply \@seen, [ $circular, $circular ];
}

# on_object: trigger the on_object callback for a Regexp, a GLOB, and a blessed
# object
{
    my @on_object;

    my $on_object = sub {
        my ($folder, $value) = @_;
        isa_ok $folder, 'Hash::Fold';
        push @on_object, $_[1];
        return $value;
    };

    my $regexp = qr{foo};
    my $glob = \*STDIN;
    my $object = bless {};

    my $hash = {
        a => { b => $regexp },
        c => { d => $glob },
        e => [ 'foo', $object, 'bar' ],
        f => { g => 42, h => 'Hello, world!' },
    };

    my $want = {
        'a.b' => $regexp,
        'c.d' => $glob,
        'e.0' => 'foo',
        'e.1' => $object,
        'e.2' => 'bar',
        'f.g' => 42,
        'f.h' => 'Hello, world!'
    };

    folds_ok $hash => $want, on_object => $on_object;
    is_deeply \@on_object, [ $regexp, $glob, $object ];
}

# on_object: trigger the on_object callback for an object and turn it into a
# non-terminal
{
    my $expand_terminal = sub {
        my ($folder, $value) = @_;
        isa_ok $folder, 'Hash::Fold';
        isa_ok $value, __PACKAGE__;
        my $expanded = { %$value };
        return $expanded;
    };

    my $folder_without_expand = Hash::Fold->new();
    my $folder_with_expand = Hash::Fold->new(on_object => $expand_terminal);
    my $object = bless { foo => 'bar', baz => 'quux' };

    my $hash = {
        a => $object,
        b => 42,
    };

    my $want_without_expand = {
        a => $object,
        b => 42,
    };

    my $want_with_expand = {
        'a.foo' => 'bar',
        'a.baz' => 'quux',
        'b'     => 42
    };

    my $got_without_expand = $folder_without_expand->fold($hash);
    my $got_with_expand = $folder_with_expand->fold($hash);

    is_deeply $got_without_expand, $want_without_expand;
    is_deeply $got_with_expand, $want_with_expand;

    # the folder options shouldn't make a difference here as far as unfolding is
    # concerned
    is_deeply $folder_without_expand->unfold($got_without_expand), $hash; # roundtrip
    is_deeply $folder_with_expand->unfold($got_with_expand), $hash; # roundtrip
}

# on_object: combine terminal expansion with the circular-reference check i.e.
# if we convert a terminal into an unblessed hashref, we should detect a
# circular reference in that hashref. check that the nested self-reference is
# detected and returned as a terminal
{
    my $expand_terminal = sub {
        my ($folder, $value) = @_;
        isa_ok $folder, 'Hash::Fold';
        isa_ok $value, __PACKAGE__;
        my $expanded = { %$value };
        $expanded->{self} = $expanded;
        return $expanded;
    };

    my $expanded = {
        foo => { bar => 'baz' },
    };

    $expanded->{self} = $expanded;

    my $hash = {
        a => $expanded,
        b => 42,
    };

    my $want = {
        'a.foo.bar' => 'baz',
        'a.self'    => $expanded,
        'b'         => 42
    };

    folds_ok $hash => $want, on_object => $expand_terminal;
}

# squashed bug: make sure empty arrays and hashes are handled correctly (i.e.
# not removed!)
{
    my $hash = {
        array => [ [], {} ],
        hash  => {
            array => [],
            hash  => {}
        }
    };

    my $want = {
        'array.0'    => [],
        'array.1'    => {},
        'hash.array' => [],
        'hash.hash'  => {},
    };

    folds_ok $hash => $want;
}

# noted potential failure in code
{
    my $hash = {
        foo => 'bar',
        1   => 'aaagh!',
        baz => 'quux',
    };

    my $want = {
        'foo'    => 'bar',
        '1'      => 'aaagh!',
        'baz'    => 'quux',
    };

    folds_ok $hash => $want;
}

# failing extension of noted potential failure in code
TODO: {
    my $hash = {
        bar => {
            foo => 'bar',
            1   => 'aaagh!',
            baz => 'quux',
        }
    };

    my $want = {
        'bar.foo'    => 'bar',
        'bar.1'      => 'aaagh!',
        'bar.baz'    => 'quux',
    };

    local $TODO = 'Array/hash ambiguity not resolved correctly at the moment';
    folds_ok $hash => $want;
}
