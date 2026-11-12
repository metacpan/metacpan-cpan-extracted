#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Scalar::Util qw(blessed);
use Test::More;
use Sample;

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-sample.xml') );

my $class = ref($map);

# Unknown methods must die like any other Perl object method call.
eval { $map->no_such_method() };
like($@, qr/^Can't locate object method "no_such_method" via package "\Q$class\E"/,
     'Unknown method dies with the standard Perl-style message');
like($@, qr/\bat \Q$0\E line \d+/,
     'Error is reported at the caller, not inside Map::Tube');

eval { my @lines = $map->get_Iines() };
like($@, qr/Can't locate object method "get_Iines"/,
     'Near-miss typo of a real method is not silently ignored');

# Must die in list context as well as scalar context.
eval { my @r = $map->xxx() };
ok($@, 'Unknown method dies in list context');

# Class-method style call (invocant is a string, not an object).
eval { Sample->no_such_class_method() };
like($@, qr/Can't locate object method "no_such_class_method" via package "Sample"/,
     'Unknown method called on the class dies too');

SKIP: {
    skip 'Map::Tube::Plugin::FuzzyFind is installed', 2 if $map->can('fuzzy_find');

    eval { $map->fuzzy_find(search => 'Baker', objects => 0) };
    my $e = $@;
    ok(blessed($e) && $e->isa('Map::Tube::Exception::MissingPluginFuzzyFind'),
       'Missing plugin method still throws MissingPluginFuzzyFind');
    like("$e", qr/Missing plugin Map::Tube::Plugin::FuzzyFind/,
         'Missing plugin message unchanged');
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    {
        my $tmp = Sample->new( xml => File::Spec->catfile('t', 'map-sample.xml') );
    }
    is_deeply(\@warnings, [], 'Object destruction does not trigger AUTOLOAD errors');
}

ok(!$map->can('no_such_method'), 'can() still returns false for unknown methods');

done_testing;
