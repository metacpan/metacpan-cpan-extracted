use Test::More tests => 7;
use HTML::HTML5::Outline 0.004 rdf => 0;

my $xhtml = <<'XHTML';
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb">
	<head>
		<title>Test</title>
	</head>
	<body>
		<h1 role=":superman">Hello</h1>
		<h2>Universe</h2>
		<h3>Possibility of a Multiverse?</h3>
		<blockquote cite="http://example.com/multiverse" xml:lang="en-us">
			<h1>What's a Multiverse?</h1>
			<h2>In Layman's Terms</h2>
			<h2>In Astrophysics</h2>
		</blockquote>
		<h2>World</h2>
		<h2>Country</h2>
		<h1>Goodbye</h1>
		<h2>Cruel World</h2>
	</body>
</html>
XHTML

my $data = HTML::HTML5::Outline
	->new($xhtml, uri => 'http://example.com/')
	->to_hashref
	;
	
ok(defined $data, 'An outline was generated.');
is($data->{class}, 'Outline', 'root is an outline');
is(scalar @{$data->{children}}, 2, 'root contains two child sections');
is($data->{children}[0]{header}{content}, 'Hello', 'first section correct title');
is($data->{children}[1]{header}{content}, 'Goodbye', 'second section correct title');

is($data->{children}[0]{children}[0]{children}[0]{children}[0]{class}, 'Outline', 'nested outline found');
is($data->{children}[0]{children}[0]{children}[0]{children}[0]{children}[0]{header}{content}, "What's a Multiverse?", 'nested outline seems in order');
