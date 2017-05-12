#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use EO::System::Perl;

ok( 1, "loaded" );
ok( my $perl = EO::System::Perl->new() );
ok( $perl == EO::System::Perl->new(), "is a singleton" );
is( $perl->binary, $^X, "$^X");
is( $perl->version, $], "$]");
ok( my $inc = $perl->include_path );
isa_ok( $inc, 'EO');
isa_ok( $inc, 'EO::Collection');
isa_ok( $inc, 'EO::Array');
is(
   scalar( $inc->iterator ),
   scalar( @INC ),
   "There are " . scalar(@INC) . " directories in your include"
  );

is($perl->can_thread, !!$Config::Config{usethreads}, "threading");
ok($perl->architecture);

is($perl->architecture, $Config::Config{archname},"we have an architecture");

