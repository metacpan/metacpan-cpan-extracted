=head1 PURPOSE

Exercise C<< JSON::Path::set >>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=83249>.

=head1 AUTHOR

Mitsuhiro Nakamura

=head1 COPYRIGHT AND LICENCE

Copyright 2013 Mitsuhiro Nakamura.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use strict;
use warnings;
use Test::More;
use JSON::Path -all;

use JSON;
my $object = from_json(<<'JSON');
{
	"store": {
		"book": [
			{
				"category": "reference",
				"author":   "Nigel Rees",
				"title":    "Sayings of the Century",
				"price":    8.95
			},
			{
				"category": "fiction",
				"author":   "Evelyn Waugh",
				"title":    "Sword of Honour",
				"price":    12.99
			},
			{
				"category": "fiction",
				"author":   "Herman Melville",
				"title":    "Moby Dick",
				"isbn":     "0-553-21311-3",
				"price":    8.99
			},
			{
				"category": "fiction",
				"author":   "J. R. R. Tolkien",
				"title":    "The Lord of the Rings",
				"isbn":     "0-395-19395-8",
				"price":    22.99
			}
		],
		"bicycle": {
			"color": "red",
			"price": 19.95
		}
	}
}
JSON

my $titles = '$.store.book[*].title';
my $jpath = JSON::Path->new($titles);

is_deeply(
	[ $jpath->values($object) ],
	[
		"Sayings of the Century",
		"Sword of Honour",
		"Moby Dick",
		"The Lord of the Rings",
	]
);

is(
	$jpath->set($object => 'TBD', 2),
	2,
);

is_deeply(
	[ $jpath->values($object) ],
	[
		"TBD",
		"TBD",
		"Moby Dick",
		"The Lord of the Rings",
	],
);

my $author = '$.store.book[2].author';
$jpath = JSON::Path->new($author);

is(
	$jpath->value($object),
	"Herman Melville",
);

is(
	$jpath->set($object => 'Anon'),
	1,
);

is(
	$jpath->value($object),
	'Anon',
);

done_testing;
