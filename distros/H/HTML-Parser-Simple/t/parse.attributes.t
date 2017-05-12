use Test::More tests => 5;
use strict;
use warnings;

use HTML::Parser::Simple::Attributes;

my $p = HTML::Parser::Simple::Attributes -> new
(
	a_string =>
	q{type=text name="my_name"
		value='my value'
		id="O'Hare"
		with_space = "true"
    }
);

my $a = $p -> parse;

is($a->{type},'text', 'unquoted attribute is parsed');
is($a->{name},'my_name', 'double quoted attribute is parsed');
is($a->{value},'my value', 'single quoted attribute with space is parsed');
is($a->{id},"O'Hare", 'double quoted attribute with embedded single quote is parsed');
is($a->{with_space},"true", 'attribute with spaces around "=" is parsed');
