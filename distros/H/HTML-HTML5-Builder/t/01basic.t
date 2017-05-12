use Test::More tests => 2;
BEGIN { use_ok('HTML::HTML5::Builder') };

HTML::HTML5::Builder->import(qw'meta :standard');

my $document = html(
	-lang => 'en',
	head(
		title('Test', \(my $foo)),
		COMMENT('Foo'),
		meta(-charset => 'utf-8'),
	),
	body(
		h1('Test'),
		p('This is a test.'),
		XML_CHUNK('<p>Yet another test.</p><div>Foo</div>'),
	),
	RAW_CHUNK('<!--?>'),
);

$foo->setAttribute('lang', 'en-GB');

is("$document",
	'<!DOCTYPE html><html lang=en><title lang=en-GB>Test</title><!--Foo--><meta charset=utf-8><h1>Test</h1><p>This is a test.<p>Yet another test.</p><div>Foo</div><!--?>',
	'Works.');
