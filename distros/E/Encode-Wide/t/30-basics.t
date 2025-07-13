use strict;
use warnings;

use Test::Most;
use Encode::Wide qw(wide_to_html wide_to_xml);

my @tests = (
	{
		name	=> 'Plain ASCII unchanged',
		input   => 'Hello world!',
		html	=> 'Hello world!',
		xml	 => 'Hello world!',
	}, {
		name	=> 'Non-breaking space',
		input   => "Hello\x{00A0}world",
		html	=> 'Hello world',
		xml	 => 'Hello world',
	}, {
		name	=> 'Latin1 characters',
		input   => "Café déjà vu – naïve façade",
		html	=> 'Caf&eacute; d&eacute;j&agrave; vu &ndash; na&iuml;ve fa&ccedil;ade',
		xml	 => 'Caf&#x0E9; d&#x0E9;j&#x0E0; vu - na&#x0EF;ve fa&#x0E7;ade',
	}, {
		name	=> 'Hyperlink entities stripped',
		input   => '<a href="https://example.com">link</a>',
		html	=> '&lt;a href=&quot;https://example.com&quot;&gt;link&lt;/a&gt;',
		xml	 => '&lt;a href=&quot;https://example.com&quot;&gt;link&lt;/a&gt;',
	}, {
		name	=> 'Keep hrefs',
		input   => '<a href="https://example.com">',
		html	=> '<a href="https://example.com">',
		xml	 => '<a href="https://example.com">',
		args	=> { keep_hrefs => 1 },
	}, {
		name	=> 'Smart quotes',
		input   => '“Hello” — she said…',
		html	=> '&quot;Hello&quot; &mdash; she said...',
		xml	 => '&quot;Hello&quot; - she said...',
	}, {
		name	=> 'Apostrophe handling',
		input   => "It's a test ‘quoted’",
		html	=> 'It&apos;s a test &apos;quoted&apos;',
		xml	 => 'It&apos;s a test &apos;quoted&apos;',
	}, {
		name	=> 'Keep apostrophes',
		input   => "It's a test ‘quoted’",
		html	=> "It's a test &apos;quoted&apos;",
		args	=> { keep_apos => 1 },
	},
);

foreach my $test (@tests) {
	my $args = $test->{args} || {};
	my $html = wide_to_html(string => $test->{input}, %{$args});
	like $html, qr/^\P{Unassigned}*$/, "$test->{name} - HTML output is ASCII-safe";
	is $html, $test->{html}, "$test->{name} - HTML correct output" if defined $test->{html};

	my $xml = wide_to_xml(string => $test->{input}, %$args);
	like $xml, qr/^\P{Unassigned}*$/, "$test->{name} - XML output is ASCII-safe";
	is $xml, $test->{xml}, "$test->{name} - XML correct output" if defined $test->{xml};
}

# Invalid input (undef string) should die
throws_ok {
	wide_to_html()
} qr/^Usage:.+wide_to_html\(/, 'Missing string param throws';

done_testing();
