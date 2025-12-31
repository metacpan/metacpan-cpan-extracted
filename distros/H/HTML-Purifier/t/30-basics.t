use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('HTML::Purifier') }

subtest "Basic Purification" => sub {
	my $purifier = HTML::Purifier->new(
		allow_tags => [qw(p b i a)],
		allow_attributes => {
			a => [qw(href title)],
		},
	encode_invalid_tags => 0
	);

	my $input_html = '<p><b>Hello, <script>alert("XSS");</script></b> <a href="world">world</a></p>';
	my $purified_html = $purifier->purify($input_html);

	is $purified_html, '<p><b>Hello, </b> <a href="world">world</a></p>', "Basic purification should remove script and invalid attributes";
};

subtest "Allowing Comments" => sub {
	my $purifier = HTML::Purifier->new(
		allow_tags => [qw(p b i a)],
		allow_attributes => {
			a => [qw(href title)],
		},
		strip_comments => 0,
	);

	my $input_html = '<!-- FOO --><p><b>Hello, </b></p>';
	my $purified_html = $purifier->purify($input_html);

	is $purified_html, '<!-- FOO --><p><b>Hello, </b></p>', "Comments should be allowed";
};

subtest "Stripping Comments" => sub {
	my $purifier = HTML::Purifier->new(
		allow_tags => [qw(p b i a)],
		allow_attributes => {
			a => [qw(href title)],
		},
		strip_comments => 1,
	);

	my $input_html = '<!-- FOO --><p><b>Hello, </b></p>';
	my $purified_html = $purifier->purify($input_html);

	is $purified_html, '<p><b>Hello, </b></p>', "Comments should be stripped";
};

subtest "Encoding Invalid Tags" => sub {
	my $purifier = HTML::Purifier->new(
		allow_tags => [qw(p b i a)],
		allow_attributes => {
			a => [qw(href title)],
		},
		encode_invalid_tags => 1,
	);

	my $input_html = '<my-custom-tag>Hello</my-custom-tag>';
	my $purified_html = $purifier->purify($input_html);

	is $purified_html, '&lt;my-custom-tag&gt;Hello&lt;/my-custom-tag&gt;', "Invalid tags should be encoded";
};

subtest "Not Encoding Invalid Tags" => sub {
	my $purifier = HTML::Purifier->new(
		allow_tags => [qw(p b i a)],
		allow_attributes => {
			a => [qw(href title)],
		},
		encode_invalid_tags => 0,
	);

	my $input_html = '<my-custom-tag>Hello</my-custom-tag>';
	my $purified_html = $purifier->purify($input_html);

	is $purified_html, 'Hello', "Invalid tags should be removed";
};

subtest "Attribute Encoding" => sub {
	my $purifier = HTML::Purifier->new(
		allow_tags => [qw(a)],
		allow_attributes => {
			a => [qw(href)],
		},
	);

	my $input_html = '<a href="javascript:alert(\'XSS\')">link</a>';
	my $purified_html = $purifier->purify($input_html);

	is $purified_html, '<a href="javascript:alert(&#39;XSS&#39;)">link</a>', "Attribute values should be encoded";
};

subtest "Case Insensitivity" => sub {
	my $purifier = HTML::Purifier->new(
		allow_tags => [qw(P B I A)],
		allow_attributes => {
			a => [qw(HREF TITLE)],
		},
	);

	my $input_html = '<p><b><i><a>Test</a></i></b></p>';
	my $purified_html = $purifier->purify($input_html);

	# Fixed expected value to match auto-closed </p>
	is $purified_html, '<p><b><i><a>Test</a></i></b></p>', "Tags and attributes should be case-insensitive";
};

done_testing();
