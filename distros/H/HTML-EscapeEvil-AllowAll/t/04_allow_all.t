
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-EscapeEvil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
use strict;

use HTML::EscapeEvil::AllowAll;

my $allow = HTML::EscapeEvil::AllowAll->new;

# ==================================================== #
# 1
# allow_comment Check
# ==================================================== #
ok($allow->allow_comment);

# ==================================================== #
# 2
# allow_declaration Check
# ==================================================== #
ok($allow->allow_declaration);

# ==================================================== #
# 3
# allow_process Check
# ==================================================== #
ok($allow->allow_process);

# ==================================================== #
# 4
# allow_entity_reference Check
# ==================================================== #
ok($allow->allow_entity_reference);

# ==================================================== #
# 5
# allow_entity_script Check
# ==================================================== #
ok($allow->allow_script);

# ==================================================== #
# 6
# allow_entity_style Check
# ==================================================== #
ok($allow->allow_style);

# ==================================================== #
# 7
# collection_process Check
# ==================================================== #
ok($allow->collection_process);

# ==================================================== #
# 8
# allow_tags Check
# ==================================================== #
my @tags = $allow->get_allow_tags;
ok(scalar @tags);

# ==================================================== #
# 9
# allow_tags Check part 2
# ==================================================== #
my $tag = $tags[sprintf "%d", rand($#tags)];
ok($allow->is_allow_tags($tag));

# ==================================================== #
# 10
# deny_tags Check
# ==================================================== #
ok(!$allow->deny_tags);

$allow->clear;

