use Test::More tests => 8;
use HTML::Microformats;

my $html = <<'HTML';
<html lang=en>

	<section class="vcard">
		<h1 class="fn">Neil Armstrong</h1>
		<a href="/tag/Astronaut" rel="tag">Space Guy</a>
	</section>
	
	<section class="hentry">
		<h1 class="entry-title">Bee Keeping</h1>
		<a href="/tag/Bees" rel="foo tag bar">Bees</a>
	</section>
	
	<a rel="tag" href="/tag/Cats">Cats</a>

HTML

my $document = HTML::Microformats->new_document($html, 'http://example.com/');
$document->assume_all_profiles;

my @tags = sort { $a->get_tag cmp $b->get_tag }
	$document->objects('RelTag');

is($tags[0]->get_tag,
	'Astronaut',
	'tag Astronaut found');

is($tags[1]->get_tag,
	'Bees',
	'tag Bees found');

is($tags[2]->get_tag,
	'Cats',
	'tag Cats found');
	
for my $i (0..2)
{
	is($tags[$i]->get_tagspace,
		'http://example.com/tag/',
		'tag has correct tag space');
}

my $model = $document->model;

is($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/'),
		RDF::Trine::Node::Resource->new('http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'),
		undef),
	3,
	'Page tagged with three tags.');

my ($armstrong) = $document->objects('hCard');

is($model->count_statements(
		$armstrong->id(1),
		RDF::Trine::Node::Resource->new('http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'),
		undef),
	1,
	'VCard tagged.');

