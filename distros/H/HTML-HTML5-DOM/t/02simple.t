use Test::More tests => 18;
use HTML::HTML5::DOM;

my $dom = HTML::HTML5::DOM->parse(\*DATA);

is(
	$dom->title,
	"The Title",
	"HTMLDocument->title",
);

is(
	$dom->anchors->get_node(1)->name,
	"table",
	"HTMLDocument->anchors and HTMLAnchorElement->name",
);

is(
	$dom->forms->get_node(1)->method,
	"get",
	"HTMLDocument->forms and HTMLFormElement->method",
);

ok(
	$dom->implementation->hasFeature(Core => 2.0),
	"HTMLDocument->implementation and HTML::HTML5::DOM->hasFeature(Core => 2.0)",
);

is(
	$dom->xmlVersion,
	undef,
	"HTMLDocument->xmlVersion",
);

my ($link) = $dom->getElementsByTagName('link');
ok(
	$dom->head->p5_contains($link),
	"HTMLDocument->head and HTMLElement->p5_contains",
);

ok(
	!$dom->body->p5_contains($link),
	"HTMLDocument->body and neg for HTMLElement->p5_contains",
);

isa_ok(
	$dom->links->get_node(1)->href,
	"URI",
	"HTMLAnchorElement->href",
);

is(
	$dom->links->get_node(1)->href->as_string,
	"http://www.example.com/",
	"HTMLAnchorElement->href",
);

isa_ok(
	$dom->forms->get_node(1)->elements,
	-HTMLFormControlsCollection,
	"HTMLFormElement->elements",
);

is(
	$dom->forms->get_node(1)->elements->p5_wwwFormUrlencoded,
	'q=foo',
	"HTMLFormControlsCollection->p5_wwwFormUrlencoded",
);

my $submit = $dom->forms->get_node(1)->submit;
isa_ok(
	$submit,
	'HTTP::Request',
	"HTMLFormElement->submit",
);

is(
	$submit->uri->as_string,
	'http://www.example.com/search?q=foo',
	'HTMLFormElement->submit->uri is correct URI',
);

is(
	$dom->p5_tables->get_node(1)->caption->textContent,
	'A table',
	'HTMLDocument->p5_tables and HTMLTableElement->caption',
);

ok(
	$dom->p5_tables->get_node(1)->deleteCaption,
	'HTMLTableElement->deleteCaption',
);

is(
	scalar $dom->p5_tables->get_node(1)->caption,
	undef,
	'HTMLDocument->p5_tables and HTMLTableElement->caption',
);

isa_ok(
	$dom->p5_tables->get_node(1)->createCaption,
	'caption',
	'HTMLTableElement->createCaption',
);

is_deeply(
	[$dom->getElementsByTagName('link')->get_node(1)->relList],
	[qw< stylesheet holoitem >],
	'HTMLLinkElement->relList',
)

__DATA__
<!doctype html>
<html>
	<head profile="http://www.w3.org/1999/xhtml/vocab">
		<title>The Title</title>
		<link
			rel="stylesheet holoitem holoitem stylesheet"
			type="text/css"
			media="hologram"
			href="hologram.css"
		>
	</head>
	<body>
		<h1>The Heading</h1>
		<table>
			<caption><a name="table"></a>A table</caption>
			<tr>
				<td><a href="http://www.example.com/">a cell</a></td>
			</tr>
		</table>
		<form action="http://www.example.com/search" method="get">
			<fieldset>
				<legend>A search form</legend>
				<label for="q">search terms</label>
				<input id="q" name="q" value="foo">
				<br>
				<input type="submit" value="search">
			</fieldset>
		</form>
	</body>
</html>
