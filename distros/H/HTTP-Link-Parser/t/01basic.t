=pod

=encoding utf-8

=head1 PURPOSE

Check HTTP Link headers can be parsed.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2014 by Toby Inkster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut

use strict;
use warnings;
use Test::More tests => 1;

use HTTP::Link::Parser ();

# Create a test response to parse.
use HTTP::Response;
my $response = HTTP::Response->new( 200 );
$response->push_header("Base" => "http://example.org/subject");
$response->push_header("Link" => "<http://example.net/absolute>; rel=\"http://example.net/rel/one http://example.net/rel/two\"; title=\"absolute\"");
$response->push_header("Link" => "<relative>; rel=\"three\"; title=\"relative\"");
$response->push_header("Link" => "<nextdoc>; rel=\"next\"; title=\"relative\"; type=\"TEXT/HTML\"; hreflang=en");
$response->push_header("Link" => "<subject>; rel=\"prev\"; title=\"subject\"; anchor=\"nextdoc\"");
$response->push_header("Link" => "<author>; rev=\"made\"; title=\"author\";");
$response->push_header("Link" => "<german-page>; rev=\"test\"; title=\"nachstes Kapitel\"; title*=UTF-8'de'n%c3%a4chstes%20Kapitel");

my @data = sort {
	$a->{URI} cmp $b->{URI}
} @{ HTTP::Link::Parser::parse_links_to_list($response) };

is_deeply(
	\@data,
	[
		{
			'URI' => bless( do{\(my $o = 'http://example.net/absolute')}, 'URI::http' ),
			'rel' => [
				'http://example.net/rel/one',
				'http://example.net/rel/two'
			],
			'title' => 'absolute'
		},
		{
			'URI' => bless( do{\(my $o = 'http://example.org/author')}, 'URI::http' ),
			'rev' => [
				'made'
			],
			'title' => 'author'
		},
		{
			'URI' => bless( do{\(my $o = 'http://example.org/german-page')}, 'URI::http' ),
			'rev' => [
				'test'
			],
			'title' => 'nachstes Kapitel',
			'title*' => [
				bless( [
					"n\x{e4}chstes Kapitel",
					undef,
					'de'
				], 'HTTP::Link::Parser::PlainLiteral' )
			]
		},
		{
			'URI' => bless( do{\(my $o = 'http://example.org/nextdoc')}, 'URI::http' ),
			'hreflang' => [
				'en'
			],
			'rel' => [
				'next'
			],
			'title' => 'relative',
			'type' => 'TEXT/HTML'
		},
		{
			'URI' => bless( do{\(my $o = 'http://example.org/relative')}, 'URI::http' ),
			'rel' => [
				'three'
			],
			'title' => 'relative'
		},
		{
			'URI' => bless( do{\(my $o = 'http://example.org/subject')}, 'URI::http' ),
			'anchor' => bless( do{\(my $o = 'http://example.org/nextdoc')}, 'URI::http' ),
			'rel' => [
				'prev'
			],
			'title' => 'subject'
		},
	],
) or diag explain(\@data);

