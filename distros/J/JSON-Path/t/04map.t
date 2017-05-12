=head1 PURPOSE

Test C<jpath_map> exported function.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2012-2013 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

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

my $path1 = '$.store.book[*].title';

jpath_map { uc $_ } $object, '$.store.book[*].title';

is_deeply(
	[ jpath1($object, $path1) ],
	[ map uc,'Sayings of the Century' ],
);

is_deeply(
	[ jpath($object, $path1) ],
	[ map uc, 'Sayings of the Century', 'Sword of Honour', 'Moby Dick', 'The Lord of the Rings' ],
);

is(
	JSON::Path->new('$.store.book[*].author')->set($object => 'Anon', 2),
	2,
);

is_deeply(
	[ jpath($object, '$.store.book[*].author') ],
	[ 'Anon', 'Anon', 'Herman Melville', 'J. R. R. Tolkien' ],
);

done_testing();
