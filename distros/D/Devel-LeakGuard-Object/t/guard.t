#!perl

use latest;

use Data::Dumper;
use Test::Differences;
use Test::More tests => 20;

use Devel::LeakGuard::Object::State;
use Devel::LeakGuard::Object qw( leakguard );

package Foo;

use strict;
use warnings;

sub new {
    my ( $class, $name ) = @_;
    return bless { name => $name }, $class;
}

package main;

@Bar::ISA = qw( Foo );

{
    eval 'leakguard {}';
    ok !$@, 'no error from bare leakguard' or diag $@;
}

{
    my $leaks = {};
    my $foo1  = Foo->new( '1foo1' );
    my $bar1  = Bar->new( '1bar1' );

    leakguard {
        my $foo2 = Foo->new( '1foo2' );
    }
    on_leak => sub { $leaks = shift };

    eq_or_diff $leaks, {}, 'no leaks';
}

{
    my $leaks = {};
    my $foo1  = Foo->new( '2foo1' );
    my $bar1  = Bar->new( '2bar1' );

    leakguard {
        my $foo2 = Foo->new( '2foo2' );
        $foo2->{me} = $foo2;
    }
    on_leak => sub { $leaks = shift };

    eq_or_diff $leaks, { Foo => [ 0, 1 ] }, 'leaks';
}

# Some versions of Carp.pm/perl emit a full stop (".") after the line
# number and some don't. We're going to handle both cases here.
sub normalize_line_num
{
    my ($w) = @_;

    s/line \d+\.?/line #/g for @$w;

    return;
}

{
    my @w = ();
    local $SIG{__WARN__} = sub { push @w, @_ };
    leakguard {
        my $foo1 = Foo->new( '3foo1' );
        $foo1->{me} = $foo1;
    };
    normalize_line_num(\@w);
    eq_or_diff [@w],
    [   "Object leaks found:\n"
        . "  Class Before  After  Delta\n"
        . "  Foo        1      2      1\n"
        . "Detected at t/guard.t line #\n" ], 'implicit warn';
}

{
    my @w = ();
    local $SIG{__WARN__} = sub { push @w, @_ };
    leakguard {
        my $foo1 = Foo->new( '3foo1' );
        $foo1->{me} = $foo1;
    }
    on_leak => 'ignore';
    eq_or_diff [@w], [], 'ignore';
}

{
    my @w = ();
    local $SIG{__WARN__} = sub { push @w, @_ };
    leakguard {
        my $foo1 = Foo->new( '4foo1' );
        $foo1->{me} = $foo1;
    }
    on_leak => 'warn';
    normalize_line_num(\@w);
    eq_or_diff [@w],
    [   "Object leaks found:\n"
        . "  Class Before  After  Delta\n"
        . "  Foo        2      3      1\n"
        . "Detected at t/guard.t line #\n" ], 'explicit warn';
}

{
    my @w = ();
    local $SIG{__DIE__} = sub { push @w, @_ };
    eval {
        leakguard {
            my $foo1 = Foo->new( '5foo1' );
            $foo1->{me} = $foo1;
        }
        on_leak => 'die';
    };
    normalize_line_num(\@w);
    eq_or_diff [@w],
    [   "Object leaks found:\n"
        . "  Class Before  After  Delta\n"
        . "  Foo        3      4      1\n"
        . "Detected at t/guard.t line #\n" ], 'die';
}

{
    eq_or_diff try_leak( {}, { Foo => 2 } ), { Foo => 2 }, 'leak 2 foo';
    eq_or_diff try_leak( {}, { Foo => 1, Baz => 1 } ),
    { Foo => 1, Baz => 1 }, 'leak 1 foo, 1 baz';
    eq_or_diff try_leak( { only => 'Baz' },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 } ),
    { Baz => 1 }, 'only Baz';
    eq_or_diff try_leak( { exclude => 'Baz' },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 } ),
    { Foo => 1, Bazzer => 1, BizBaz => 1 }, 'exclude Baz';
    eq_or_diff try_leak( { only => 'Baz*' },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 } ),
    { Bazzer => 1, Baz => 1 }, 'only Baz*';
    eq_or_diff try_leak(
        { only => 'Baz*', exclude => qr{e} },
        { Foo  => 1,      Baz     => 1, Bazzer => 1, BizBaz => 1 }
    ),
    { Baz => 1 }, 'only Baz*, exclude /e/';
    eq_or_diff try_leak( { only => [ 'Baz*', 'Foo' ] },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 } ),
    { Foo => 1, Bazzer => 1, Baz => 1 }, 'only Baz*, Foo';
    eq_or_diff try_leak( { expect => {} },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 } ),
    { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 }, 'expect nothing';
    eq_or_diff try_leak( { expect => { Foo => 2 } },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 } ),
    { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 }, 'expect 2 x Foo';
    eq_or_diff try_leak( { expect => { Foo => 1 } },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 } ),
    { Baz => 1, Bazzer => 1, BizBaz => 1 }, 'expect 1 x Foo';
    eq_or_diff try_leak(
        { expect => { Foo => [ 0, 2 ] } },
        { Foo => 1, Baz => 1, Bazzer => 1, BizBaz => 1 }
    ),
    { Baz => 1, Bazzer => 1, BizBaz => 1 }, 'expect 0..2 x Foo';
    eq_or_diff try_leak(
        { expect => { Foo => [ 0, 2 ] } },
        { Foo => 2, Baz => 1, Bazzer => 1, BizBaz => 1 }
    ),
    { Baz => 1, Bazzer => 1, BizBaz => 1 }, 'expect 0..2 x Foo';
    eq_or_diff try_leak(
        { expect => { Foo => [ 0, 2 ] } },
        { Foo => 3, Baz => 1, Bazzer => 1, BizBaz => 1 }
    ),
    { Foo => 3, Baz => 1, Bazzer => 1, BizBaz => 1 },
    'expect 0..2 x Foo';
}

sub try_leak {
    my ( $options, $leak ) = @_;
    my $leaked = {};
    leakguard { mk_leaker( %$leak )->() } %$options,
    on_leak => sub { $leaked = shift };
    $_ = $_->[1] - $_->[0] for values %$leaked;
    return $leaked;
}

sub mk_leaker {
    my %leak = @_;
    return sub {
        while ( my ( $pkg, $count ) = each %leak ) {
            unless ( $pkg eq 'Foo' ) {
                no strict 'refs';
                @{"${pkg}::ISA"} = qw( Foo );
            }
            for ( 1 .. $count ) {
                my $thing = $pkg->new;
                $thing->{me} = $thing;    # leak
            }
        }
    };
}

# vim: expandtab shiftwidth=4
