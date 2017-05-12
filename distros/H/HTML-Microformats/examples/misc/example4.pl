use 5.010;
use lib "lib";
use HTML::Microformats;
use strict;
use JSON;
use Data::Dumper;
use RDF::TrineShortcuts;

my $html = <<HTML;
	<div class="hentry hnews" id="foo">
	<h1>Foo</h1>
	<p class="dateline">London, UK (<span class="geo">12.34,56.78</span>).</p>
	<p class="entry-summary entry-content">Foo bar.</p>
	<p class="vcard author"><a href="mailto:eve\@example.com" class="fn url">Eve</a></p>
	<a rel="tag" href="test">Test</a>
	<span class="updated published">2010-03-01T15:00:00+0000</span>
	</div>
HTML

my $doc  = HTML::Microformats->new_document($html, 'http://example.net/')->assume_all_profiles;
my @news = $doc->objects('hNews');

say $news[0]->get_summary;
$news[0]->set_summary('Bar foo.');
$news[0]->set_updated('2010-03-02T16:00:00+0000', '2010-03-03T16:00:00+0000');
$news[0]->add_updated('2010-03-04T16:00:00+0000', '2010-03-05T16:00:00+0000');
$news[0]->set_link('http://example.com/');
say $news[0]->get_author->[0]->get_nickname->[0];
print to_json($news[0]->data, {pretty=>1,canonical=>1,convert_blessed=>1});

#print $doc->json(pretty=>1,canonical=>1)."\n";
#print rdf_string($doc->model, 'rdfxml')."\n";
#print Dumper($doc);
