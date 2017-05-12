#!/usr/local/bin/perl

# contributed by Trevor Schellhorn

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

use_ok('HTML::FillInForm');

my $html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
</form>
];

my $result = HTML::FillInForm->new->fill(
					 scalarref => \$html,
					 fdat => {
					   two => "new val 2",
					 },
					 disable_fields => [qw(two)],
					 );

ok($result =~ /not disturbed/ && $result =~ /\bone/,'don\'t disable 1');
ok($result =~ /new val 2/ && $result =~ /\btwo/ && $result =~ /disabled="disabled"/,'disable 2');
$result = HTML::FillInForm->new->fill(
					 scalarref => \$html,
					 fdat => {
					   two => "new val 2",
					 },
					 disable_fields => 'two',
					 );

ok($result =~ /not disturbed/ && $result =~ /\bone/,'don\'t disable 1');
ok($result =~ /new val 2/ && $result =~ /\btwo/ && $result =~ /disabled="disabled"/,'disable 2');
