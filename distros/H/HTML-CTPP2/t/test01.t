# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-CTPP2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('HTML::CTPP2') };

use strict;

my $T = new HTML::CTPP2();
ok( ref $T eq "HTML::CTPP2", "Create object.");

# Test base methods
my @methods = qw/param reset clear_params output include_dirs load_bytecode parse_template load_udf/;
can_ok($T, @methods);

