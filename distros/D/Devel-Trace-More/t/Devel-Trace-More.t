#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Devel-Trace-More.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Devel::Trace::More') };

#########################

is( $Devel::Trace::More::IS_INTERESTING->(), 1, "Default IS_INTERESTING returns 1 with no params entered");

Devel::Trace::More::filter_on(qr/Test/);
is( $Devel::Trace::More::IS_INTERESTING->('','Stuff Test Blah', '',''),  1,  "IS_INTERESTING found something interesting with a regex");
is( $Devel::Trace::More::IS_INTERESTING->('','Stuff Thing Blah', '',''), '', "IS_INTERESTING did not find something interesting with a regex");

Devel::Trace::More::filter_on( sub { my ($p, $f, $l, $c) = @_; return index($f, 'Test') > -1; } );
is( $Devel::Trace::More::IS_INTERESTING->('','Stuff Test Blah', '',''),  1,  "IS_INTERESTING found something interesting with a code ref");
is( $Devel::Trace::More::IS_INTERESTING->('','Stuff Thing Blah', '',''), '', "IS_INTERESTING did not find something interesting with a code ref");

Devel::Trace::More::filter_on('Test');
is( $Devel::Trace::More::IS_INTERESTING->('','Stuff Test Blah', '',''),  1,  "IS_INTERESTING found something interesting with a scalar");
is( $Devel::Trace::More::IS_INTERESTING->('','Stuff Thing Blah', '',''), '', "IS_INTERESTING did not find something interesting with a scalar");
