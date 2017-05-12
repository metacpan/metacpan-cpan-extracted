use Test::More tests => 10;
use HTML::Microformats;

my $html = <<'HTML';
<html lang=en>

	<div class="hfeed" id="news">
		<div class="hentry hnews">
			<h1 class="entry-title">First</h1>
			<p class="entry-content"><span class="geo">World (<span class="latitude">0</span>, <span class="longitude">0</span>)</span></p>
		</div>
	</div>

	<div class="hfeed" id="blog">
		<div class="hentry">
			<h1 class="entry-title">First</h1>
			<p class="entry-summary entry-content">Hello</p>
			<p class="entry-content"><a href="foo" rev="vote-for">World</a></p>
		</div>
		<div class="hentry">
			<h1 class="entry-title">Second</h1>
			<div class="author vcard"><span class="fn">Bob</span></div>
		</div>
	</div>

	<address class="author vcard"><span class="fn">Alice</span></address>

HTML

my $document = HTML::Microformats->new_document($html, 'http://example.com/');
$document->assume_all_profiles;

my ($blog, $news)  = sort { $a->element->getAttribute('id') cmp $b->element->getAttribute('id') }
	$document->objects('hAtom');

my @blog_entries = @{ $blog->get_entry };
is( scalar @blog_entries,
	2,
	"Two entries found in blog.");

my @news_entries = @{ $news->get_entry };
is( scalar @news_entries,
	1,
	"One entry found in news.");

ok($news_entries[0]->isa('HTML::Microformats::Format::hNews'),
	'News item is a news item');
	
ok($news_entries[0]->isa('HTML::Microformats::Format::hEntry'),
	'News item is an entry');

is($news_entries[0]->data->{title},
	'First',
	'News item has correct entry-title');

is($news_entries[0]->get_author->[0]->get_fn,
	'Alice',
	'Implied author');

is($news_entries[0]->get_geo->[0]->get_latitude,
	'0',
	'News item has a geo');

my ($votelink) = $document->objects('VoteLinks');
is($votelink->get_voter->[0]->get_fn,
	'Alice',
	'hEntry propagates authors to VoteLinks');

is($blog_entries[0]->data->{content},
	'HelloWorld',
	'Multiple entry-content elements concatenated');

is($document->model->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://bblfish.net/work/atom-owl/2006-06-06/#Entry'),
		),
	3,
	'Three atom:Entry resources output (RDF)');

 