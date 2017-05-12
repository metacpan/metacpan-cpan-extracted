#!/usr/bin/perl

use strict;
use warnings;

use EO::System;
use Test::More no_plan => 1;

ok(1, "loaded");
ok(my $system = EO::System->new());
ok($system == EO::System->new(), "is a singleton");
is($system->in, \*STDIN);
is($system->out, \*STDOUT);
is($system->error,\*STDERR);
ok(my $perl = $system->perl);
isa_ok( $perl, 'EO' );
isa_ok( $perl, 'EO::Singleton' );
isa_ok( $perl, 'EO::System::Perl' );
ok(my $os = $system->os);
isa_ok( $os, 'EO');
isa_ok( $os, 'EO::Singleton');
isa_ok( $os, 'EO::System::OS');

