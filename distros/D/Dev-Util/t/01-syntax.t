#!/usr/bin/env perl

use Test2::V0;

use Dev::Util::Syntax;

plan tests => 12;

ok(
    ( say "Hello World" eq "Hello World" ),
    "Test if use feature :5.18 loaded."
  );

ok( defined $INC{ 'feature.pm' },  "feature loaded" );
ok( defined $INC{ 'utf8.pm' },     "utf8 loaded" );
ok( defined $INC{ 'strict.pm' },   "strict loaded" );
ok( defined $INC{ 'warnings.pm' }, "warnings loaded" );
ok( defined $INC{ 'autodie.pm' },  "autodie loaded" );
ok( defined $INC{ 'open.pm' },     "open loaded" );
ok( defined $INC{ 'version.pm' },  "version loaded" );
ok( defined $INC{ 'Readonly.pm' }, "Readonly loaded" );
ok( defined $INC{ 'Carp.pm' },     "Carp loaded" );
ok( defined $INC{ 'English.pm' },  "English loaded" );

no strict 'subs';
is( true, 1, "Test if true is loaded via builtin or boolean." );

done_testing;
