
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-EscapeEvil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use strict;
use warnings;

use HTML::EscapeEvil;
my $escapeevil;

# ==================================================== #
# 1
# Create Instance Check
# ==================================================== #
ok($escapeevil = HTML::EscapeEvil->new);

# ==================================================== #
# 2
# Accessor Method Check
# ==================================================== #
can_ok($escapeevil,qw(allow_comment allow_declaration allow_process allow_entity_reference allow_script allow_style collection_process processes));

# ==================================================== #
# 3
# Definition Method Check
# ==================================================== #
can_ok($escapeevil,qw(set_allow_tags add_allow_tags deny_tags get_allow_tags is_allow_tags deny_all filtered_html filtered_file clear clear_process parse parse_file));

$escapeevil->clear;
