=pod

=encoding utf-8

=head1 PURPOSE

Check HTTP Link headers can be parsed to an RDF model.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009-2011, 2014 by Toby Inkster

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
use Test::More;

BEGIN {
	eval { require RDF::Trine }
		? plan(tests    => 11)
		: plan(skip_all => "requires RDF::Trine")
};

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

my $M = HTTP::Link::Parser::parse_links_into_model($response);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/subject'),
		RDF::Trine::Node::Resource->new('http://example.net/rel/one'),
		RDF::Trine::Node::Resource->new('http://example.net/absolute'),
	),
	"absolute relationships",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/subject'),
		RDF::Trine::Node::Resource->new('http://www.iana.org/assignments/relation/three'),
		RDF::Trine::Node::Resource->new('http://example.org/relative'),
	),
	"relative relationships",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/subject'),
		RDF::Trine::Node::Resource->new('http://example.net/rel/two'),
		RDF::Trine::Node::Resource->new('http://example.net/absolute'),
	),
	"space-separated relationships",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/nextdoc'),
		RDF::Trine::Node::Resource->new('http://www.iana.org/assignments/relation/prev'),
		RDF::Trine::Node::Resource->new('http://example.org/subject'),
	),
	"the 'anchor' link parameter",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/author'),
		RDF::Trine::Node::Resource->new('http://www.iana.org/assignments/relation/made'),
		RDF::Trine::Node::Resource->new('http://example.org/subject'),
	),
	"the 'rev' link parameter",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/author'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/title'),
		RDF::Trine::Node::Literal->new('author'),
	),
	"the 'title' link parameter",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/subject'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/title'),
		RDF::Trine::Node::Literal->new('subject'),
	),
	"the 'title' link parameter, with 'anchor'",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/german-page'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/title'),
		RDF::Trine::Node::Literal->new('nächstes Kapitel', 'de'),
	),
	"the 'title*' link parameter",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/german-page'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/title'),
		RDF::Trine::Node::Literal->new('nachstes Kapitel'),
	),
	"'title*' fallback",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/nextdoc'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/language'),
		RDF::Trine::Node::Resource->new('http://www.lingvoj.org/lingvo/en'),
	),
	"the 'hreflang' link parameter",
);

ok(
	$M->count_statements(
		RDF::Trine::Node::Resource->new('http://example.org/nextdoc'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/format'),
		RDF::Trine::Node::Resource->new('http://www.iana.org/assignments/media-types/text/html'),
	),
	"the 'type' link parameter",
);
