#!/usr/local/bin/perl

# contributed by James Tolley

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;

use_ok('HTML::FillInForm');

my $html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
<input type="text" name="three" value="not disturbed">
</form>
];

my $result = HTML::FillInForm->new->fill(
					 scalarref => \$html,
					 fdat => {
					   two => "new val 2",
					   three => "new val 3",
					 },
					 ignore_fields => [qw(one two)],
					 );

ok($result =~ /not disturbed/ && $result =~ /\bone/,'ignore 1');
ok($result =~ /not disturbed/ && $result =~ /\btwo/,'ignore 2');
ok($result =~ /new val 3/ && $result =~ /\bthree/,'ignore 3');
