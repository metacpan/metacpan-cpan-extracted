use Test::More tests => 10;
use HTML::Microformats;

my $html = <<'HTML';
<html lang=en>

  <div class="vcard">
    <h1 class="fn org">My Org</h1>
    <p>
      <b>General Enquiries:</b>
      <span class="tel">+44 1234 567 890</span>
    </p>
    <p class="tel">
      <b><span class="type">Fax</span>:</b>
      <span class="value">+44 1234 567 891</span>
    </p>
    <p class="agent vcard">
      <span class="org">
        <abbr class="organization-name" title="My Org"></abbr>
        <b class="organization-unit fn">Help Desk</b>
      </span>
      <span class="tel">+44 1234 567 899</span>
    </p>
  </div>

HTML

my $document = HTML::Microformats->new_document($html, 'http://example.com/');
$document->assume_all_profiles;

my @cards = sort { $a->data->{fn} cmp $b->data->{fn} }
	$document->objects('hCard');

is($cards[0]->get_kind,
	'group',
	'Auto-detect group kind.');

is($cards[1]->get_kind,
	'org',
	'Auto-detect organisation kind.');

is($cards[0]->element->tagName,
	'p',
	'Can get links back to elements.');

is($cards[1]->get_tel->[0]->get_value,
	'tel:+441234567890',
	'Parsed tel without type+value');

is($cards[1]->get_tel->[1]->get_value,
	'tel:+441234567891',
	'Parsed tel with type+value');

is($cards[1]->get_agent->[0],
	$cards[0],
	'Agent works OK');
	
my $model = $document->model;

ok($model->count_statements(
		$cards[1]->id(1),
		RDF::Trine::Node::Resource->new('http://www.w3.org/2006/vcard/ns#agent'),
		$cards[0]->id(1),
		),
	"Agent works OK (RDF)"
	);

ok($model->count_statements(
		$cards[1]->id(1),
		RDF::Trine::Node::Resource->new('http://www.w3.org/2006/vcard/ns#fn'),
		RDF::Trine::Node::Literal->new('My Org', 'en'),
		),
	"Languages work OK (RDF)"
	);

ok($model->count_statements(
		$cards[1]->id(1, 'holder'),
		RDF::Trine::Node::Resource->new('http://purl.org/uF/hCard/terms/hasCard'),
		$cards[1]->id(1),
		),
	"Differentiates between vcards and their holders (RDF)"
	);

ok($model->count_statements(
		$cards[1]->id(1, 'holder'),
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
		RDF::Trine::Node::Literal->new('My Org', 'en'),
		),
	"Infers information about vcard holder from the vcard (RDF)"
	);

