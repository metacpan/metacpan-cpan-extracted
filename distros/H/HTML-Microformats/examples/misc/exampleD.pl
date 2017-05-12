use 5.010;
use lib "lib";
use HTML::Microformats;
use strict;
use JSON;
use Data::Dumper;
use RDF::TrineShortcuts;

my $html = <<HTML;
<a rel="me" href="foo1">foo1</a>
<a rel="me" href="foo2">foo2</a>
<a rel="me" href="foo3">foo3</a>
<a rel="friend met" href="bar1">bar1</a>
HTML

my $doc = HTML::Microformats->new_document($html, 'http://example.net/')->assume_all_profiles;
print rdf_string($doc->model => 'rdfxml');
