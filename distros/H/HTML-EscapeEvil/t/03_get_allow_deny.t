
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-EscapeEvil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use strict;
use warnings;

use HTML::EscapeEvil;

my($escapeevil,%option);
%option = (
			allow_comment => 1,
			allow_declaration => 1,
			allow_process => 1,
			allow_style => 1,
			allow_script => 1,
			allow_entity_reference => 1,
			collection_process => 1,
			allow_tags => [qw(html head title body)],
		);

$escapeevil = HTML::EscapeEvil->new(%option);

# ==================================================== #
# 1 - 3
# Get,Allow,Deny Check
# ==================================================== #
my @tags = $escapeevil->get_allow_tags;
is(scalar @tags,6);

$escapeevil->add_allow_tags("a");
ok($escapeevil->is_allow_tags("a"));
$escapeevil->deny_tags("a");
ok(!$escapeevil->is_allow_tags("a"));

