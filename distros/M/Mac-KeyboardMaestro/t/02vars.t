#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Mac::KeyboardMaestro qw(km_set km_get km_delete);

my $varname = "mackeyboardmaestrotestsuite";
my $unique  = time . chr(92) .chr(92). $$ . '"';

km_set $varname => $unique;
is km_get $varname, $unique, "variable was set";
km_delete $varname;
is km_get $varname, "", "variable is gone!";

# check that a totally random variable returns the empty string
is km_get "var".time.$$, "", "random var does not exist";

# check that invalid variables names produce the right error

eval { km_set "!invalid", "foo" };
like $@, qr/Invalid Keyboard Maestro variable name '!invalid'/, "km_set invalid";

eval { km_get "!invalid" };
like $@, qr/Invalid Keyboard Maestro variable name '!invalid'/, "km_get invalid";

eval { km_delete "!invalid" };
like $@, qr/Invalid Keyboard Maestro variable name '!invalid'/, "km_delete invalid";