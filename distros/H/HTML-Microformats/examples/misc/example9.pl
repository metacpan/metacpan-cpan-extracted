#!/usr/bin/perl

use lib "lib";
use HTML::Microformats;
use strict;
use JSON;
use LWP::Simple qw(get);
use Data::Dumper;
use RDF::TrineShortcuts;

my $uri  = 'http://example.com/foo';
my $html = <<HTML;

<dl class=profile>
	<dt id="rel">rel</dt>
	<dd>
		<p>Blah blah...</p>
		<dl>
			<dt id="foo">foo</dt>
			<dd>Foo blah...</dd>
			<dt>bar</dt>
			<dd>Bar blah...</d>
		</dl>
	</dd>
</dl>

HTML
utf8::upgrade($html);

my $doc  = HTML::Microformats->new_document($html, $uri);
$doc->assume_all_profiles;

print $doc->json(pretty=>1, convert_blessed=>1);
print rdf_string($doc->model, 'rdfxml');
