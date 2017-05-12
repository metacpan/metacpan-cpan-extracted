=head1 PURPOSE

Round-trip some JSON through pretty-printing.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 2;
use JSON::MultiValueOrdered;

my $str = <<'JSON';
{
	"a": [
		1,
		2,
		3
	],
	"a": true,
	"a": false,
	"a": 99.999,
	"a": null,
	"a": {
		"b": 4,
		"c": [
			1
		],
		"d": [],
		"e": {}
	}
}
JSON

my $json = JSON::MultiValueOrdered->new(pretty => 1);

ok($json->pretty);

is(
	$json->encode($json->decode($str)),
	$str,
);
