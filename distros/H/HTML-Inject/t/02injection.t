use Test::More tests => 1;
use HTML::Inject;
use XML::LibXML::PrettyPrint;

my $template = HTML::Inject::->new(target => <<'TEMPLATE');
<!doctype html>
<html>
	<head></head>
	<body>
		<div id="content"></div>
	</body>
</html>
TEMPLATE

my $pp = XML::LibXML::PrettyPrint::->new_for_html;
my $output = $pp->pretty_print($template->inject(<<'CONTENT'));
<title>Hello World</title>
<div id="content" class="main">A greeting to the planet!</div>
CONTENT

is($output->toString, <<'OUTPUT');
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Hello World</title>
	</head>
	<body>
		<div id="content" class="main">
			A greeting to the planet!
		</div>
	</body>
</html>
OUTPUT

