
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-EscapeEvil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use strict;

use HTML::EscapeEvil::AllowAll;
my $allow;

# ==================================================== #
# 1
# Create Instance Check
# ==================================================== #
ok($allow = HTML::EscapeEvil::AllowAll->new);

# ==================================================== #
# 2
# ISA HTML::EscapeEvil Check
# ==================================================== #
ok($allow->isa("HTML::EscapeEvil"));

$allow->clear;

