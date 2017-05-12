
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-EscapeEvil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
use strict;

use HTML::EscapeEvil::AllowAll;

my $allow = HTML::EscapeEvil::AllowAll->new;

# ==================================================== #
# 1
# Definition Method Check
# ==================================================== #
can_ok($allow,qw(allow_all));

$allow->clear;

