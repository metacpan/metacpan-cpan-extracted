use strict;
use warnings;

use HTML::Parser::Simple::Attributes;

use Test::More tests => 1;

# ------------------------

my($a);

eval
{
		$a = HTML::Parser::Simple::Attributes -> parse('name="name" type=""');
};

if ($@)
{
		is($$a{type}, undef, 'empty attribute croaked');
}
else
{
		BAILOUT('empty attribute failed to croak');
}
