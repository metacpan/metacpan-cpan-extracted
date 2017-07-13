
=head1 PURPOSE

Some basic Tests for handling of unicode characters in JSON data.

=head1 AUTHOR

Heiko Jansen E<lt>hjansen@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2016 Heiko Jansen.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use Test::More tests => 5;
BEGIN { use_ok('JSON::Path') }

use JSON::MaybeXS;
my $data = <<"JSON";
{
	"store": {
		"book": [
			{
				"category": "reference",
				"author":   "Randal L. Schwartz",
				"title":    "Einf\xFChrung in Perl",
				"isbn":     "9783868991451",
				"price":    34.90
			},
			{
				"category": "chartest",
				"author":   "\x{61}\x{0300}\x{0320}. u. thor",
				"title":    "Me \x{2661} Unicode",
				"price":    0.0
			}
		],
		"bicycle": {
			"color": "r\xF6tlich",
			"price": 19.95
		}
	}
}
JSON
utf8::encode($data);
my $object = decode_json($data);

my $path1 = JSON::Path->new('$.store.book[0].title');
is( "$path1", '$.store.book[0].title', "overloaded stringification" );

my @results1 = $path1->values($object);
is( $results1[0], "Einf\xFChrung in Perl", "basic value result" );

@results1 = $path1->paths($object);
is( $results1[0], "\$['store']['book']['0']['title']", "basic path result" );

my $path2    = JSON::Path->new('$.store.book[1].author');
my @results2 = $path2->values($object);
is( $results2[0], "\x{61}\x{0300}\x{0320}. u. thor", "basic value result" );

