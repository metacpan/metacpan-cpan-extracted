# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of the Math::ModInt::Event utility module.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/12_event.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 25 };
use Math::ModInt qw(mod);
use Math::ModInt::Event;
ok(1);          # modules loaded

#########################

my $a = mod(1, 2);
my $b = mod(2, 3);
my $c = eval { $a + $b };
ok(ref $c && $c->isa('Math::ModInt') && $c->is_undefined);

my $e = Math::ModInt::Event->AnyEvent;
$c = eval { $a + $b };
ok(ref $c && $c->isa('Math::ModInt') && $c->is_undefined);

my $f = $e->trap('warn');
{
    ok($f->isa('Math::ModInt::Event::Trap'));
    my $warned = undef;
    local $SIG{'__WARN__'} = sub { $warned = "@_" };

    $c = eval { $a + $b };
    ok(defined($warned) && $warned =~ /warning: different moduli/);
    ok(ref $c && $c->isa('Math::ModInt') && $c->is_undefined);

    undef $f;
    undef $e;
    undef $warned;

    $c = eval { $a + $b };
    ok(!defined $warned);
    ok(ref $c && $c->isa('Math::ModInt') && $c->is_undefined);
}

my $done = '';
$e = Math::ModInt::Event->AnyEvent;
$f = Math::ModInt::Event->AnyEvent;
my (@E, @F);
push @E, $e->trap(sub { $done .= '1'; });
push @E, $e->trap(sub { die 'custom message'; });
push @E, $e->trap(sub { $done .= '2'; });
push @F, $f->trap(sub { $done .= '3'; });
push @E, $e->trap(sub { $done .= '4'; });
$c = eval { $a + $b };
ok(!defined $c);
ok($@ =~ /custom message/);
ok($done, '432');

@F = ();
$c = eval { $a + $b };
ok(!defined $c);
ok($@ =~ /custom message/);
ok($done, '43242');
@E = ();

$e = Math::ModInt::Event->AnyEvent;
$done = '';
push @E, $e->trap(sub { $done .= '5'; });
push @E, $e->trap('die');
push @E, $e->trap(sub { $done .= '6'; });
$c = eval { $a + $b };
ok(!defined $c);
ok($@ =~ /^error: different moduli/);
ok('6' eq $done);
@E = ();

$done = '';
$e = Math::ModInt::Event->AnyEvent->trap( sub { $done .= 'a'} );
$f = Math::ModInt::Event->UndefinedResult->trap( sub { $done .= 'u' } );
my $g = Math::ModInt::Event->DifferentModuli->trap( sub { $done .= 'd' } );
$c = eval { $b + $a };
ok(ref $c && $c->isa('Math::ModInt') && $c->is_undefined);
ok($done eq 'da');

$e = Math::ModInt::Event->AnyEvent;
$f = eval { $e->trap('bogus text') };
ok(!defined $f);
ok($@ =~ /or coderef expected/);
$f = eval { $e->trap(undef) };
ok(!defined $f);
ok($@ =~ /or coderef expected/);

# static traps
Math::ModInt::Event->DifferentModuli->trap('die');
$c = eval { $a + $b };
ok(!defined $c);
ok($@ =~ /error: different moduli/);

__END__
