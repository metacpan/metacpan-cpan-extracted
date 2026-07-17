#!/usr/bin/env perl

use strict;
use warnings;

use Encode::Wide qw(wide_to_html wide_to_xml);
use Test::Most;
use Test::Returns;

my @tests = (
	{
		name	=> 'Plain ASCII unchanged',
		input   => 'Hello world?',
		html	=> 'Hello world?',
		xml	 => 'Hello world?',
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
	}, {
		name	=> 'Exclamation mark',
		input   => 'You are not right!',
		html	=> 'You are not right&excl;',
		xml	=> 'You are not right!',
	}, {
		name	=> 'Trade mark symbol',
		input   => "Acme\x{2122}",
		html	=> 'Acme&trade;',
		xml	=> 'Acme&#x2122;',
	}, {
		name	=> 'c with caron',
		input   => "\x{010D}",
		html	=> '&ccaron;',
		xml	=> '&#x10D;',
	}, {
		name	=> 'Z with caron (capital)',
		input   => "\x{017D}",
		html	=> '&Zcaron;',
		xml	=> '&#x17D;',
	}, {
		name	=> 'Z with caron in word (XML uses numeric entity)',
		input   => "SURN \x{017D}ganjar",
		html	=> 'SURN &Zcaron;ganjar',
		xml	=> 'SURN &#x17D;ganjar',
	}, {
		name	=> 'zcaron HTML entity in input decoded to numeric in XML',
		input   => 'An&zcaron;link',
		html	=> 'An&zcaron;link',
		xml	=> 'An&#x17E;link',
	}, {
		name	=> 'I circumflex (U+00CE) HTML named entity correct spelling',
		input   => "\x{00CE}",
		html	=> '&Icirc;',
		xml	=> '&#x0CE;',
	},
);

foreach my $test (@tests) {
	my $args = $test->{args} || {};
	my $html = wide_to_html(string => $test->{input}, %{$args});

	diag($test->{'input'}, "->$html") if($ENV{'TEST_VERBOSE'});
	like $html, qr/^\P{Unassigned}*$/, "$test->{name} - HTML output is ASCII-safe";
	is $html, $test->{html}, "$test->{name} - HTML correct output" if defined $test->{html};

	returns_is($html, { type => 'string', 'min' => 1, nomatch => qr/[^[:ascii:]]/ });

	$html = wide_to_html(string => \$test->{input}, %{$args});
	is $html, $test->{html}, "$test->{name} - HTML correct output, given a ref to a string" if defined $test->{html};

	undef $html;

	my $xml = wide_to_xml(string => $test->{input}, %$args);
	like $xml, qr/^\P{Unassigned}*$/, "$test->{name} - XML output is ASCII-safe";
	is $xml, $test->{xml}, "$test->{name} - XML correct output" if defined $test->{xml};

	$xml = wide_to_xml(string => \$test->{input}, %{$args});
	is $xml, $test->{xml}, "$test->{name} - XML correct output, given a ref to a string" if defined $test->{xml};

	returns_is($xml, { type => 'string', 'min' => 1, nomatch => qr/[^[:ascii:]]/ });
}

# Invalid input (undef string) should die
throws_ok {
	wide_to_html()
} qr/^Usage:.+wide_to_html\(/, 'Missing string param throws';

throws_ok {
	wide_to_xml(string => undef)
} qr/Usage: wide_to_xml\(\) string not set/, 'Missing string param throws';

done_testing();
