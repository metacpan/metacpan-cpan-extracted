use strict;
use warnings;
use Test::More;
use Eshu;

# Full HTML page
{
	my $input = <<'END';
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Test</title>
</head>
<body>
<div>
<h1>Hello</h1>
<p>World</p>
</div>
</body>
</html>
END

	my $expected = <<'END';
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>Test</title>
	</head>
	<body>
		<div>
			<h1>Hello</h1>
			<p>World</p>
		</div>
	</body>
</html>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'full HTML page');
}

# XML with PI, comments, CDATA
{
	my $input = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<!-- root config -->
<config>
<database>
<host>localhost</host>
<port>5432</port>
</database>
<cache>
<![CDATA[raw config data]]>
</cache>
</config>
END

	my $expected = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<!-- root config -->
<config>
	<database>
		<host>localhost</host>
		<port>5432</port>
	</database>
	<cache>
		<![CDATA[raw config data]]>
	</cache>
</config>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'XML with PI, comments, and CDATA');
}

# detect_lang for XML/HTML extensions
{
	is(Eshu->detect_lang('file.xml'),   'xml',  'detect xml');
	is(Eshu->detect_lang('file.xsl'),   'xml',  'detect xsl');
	is(Eshu->detect_lang('file.xslt'),  'xml',  'detect xslt');
	is(Eshu->detect_lang('file.svg'),   'xml',  'detect svg');
	is(Eshu->detect_lang('file.xhtml'), 'xml',  'detect xhtml');
	is(Eshu->detect_lang('file.html'),  'html', 'detect html');
	is(Eshu->detect_lang('file.htm'),   'html', 'detect htm');
	is(Eshu->detect_lang('file.tmpl'),  'html', 'detect tmpl');
	is(Eshu->detect_lang('file.tt'),    'html', 'detect tt');
	is(Eshu->detect_lang('file.ep'),    'html', 'detect ep');
}

# Blank lines preserved
{
	my $input = <<'END';
<root>

<child>text</child>

</root>
END

	my $expected = <<'END';
<root>

	<child>text</child>

</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'blank lines preserved');
}

# Mixed content with inline tags
{
	my $input = <<'END';
<html>
<body>
<p>Some <strong>bold</strong> and <em>italic</em> text</p>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<body>
		<p>Some <strong>bold</strong> and <em>italic</em> text</p>
	</body>
</html>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'inline tags on same line cancel out');
}

# Atom feed structure
{
	my $input = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<title>My Blog</title>
<link href="https://example.com"/>
<entry>
<title>Post One</title>
<link href="https://example.com/1"/>
<summary>First post</summary>
</entry>
<entry>
<title>Post Two</title>
<link href="https://example.com/2"/>
<summary>Second post</summary>
</entry>
</feed>
END

	my $expected = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>My Blog</title>
	<link href="https://example.com"/>
	<entry>
		<title>Post One</title>
		<link href="https://example.com/1"/>
		<summary>First post</summary>
	</entry>
	<entry>
		<title>Post Two</title>
		<link href="https://example.com/2"/>
		<summary>Second post</summary>
	</entry>
</feed>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'Atom feed structure');
}

# Namespace-prefixed XML at multiple depths
{
	my $input = <<'END';
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Header>
<auth:Token xmlns:auth="http://example.com/auth">abc123</auth:Token>
</soap:Header>
<soap:Body>
<m:GetUser xmlns:m="http://example.com/api">
<m:Id>42</m:Id>
</m:GetUser>
</soap:Body>
</soap:Envelope>
END

	my $expected = <<'END';
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Header>
		<auth:Token xmlns:auth="http://example.com/auth">abc123</auth:Token>
	</soap:Header>
	<soap:Body>
		<m:GetUser xmlns:m="http://example.com/api">
			<m:Id>42</m:Id>
		</m:GetUser>
	</soap:Body>
</soap:Envelope>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'namespace-prefixed XML with SOAP envelope');
}

done_testing();
