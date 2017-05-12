#!perl -w

use strict;
use Test::More tests => 3;

use HTML::FillInForm::Lite;

my $h = HTML::FillInForm::Lite->new();

my $src = <<'HTML';
<input name="foo" value="" />
<input name="bar" value="" />
<input name="baz" value="" />
HTML

my $result = $h->fill(\$src, {
	foo => 'value-foo',
	bar => undef,
	baz => 'value-bar',
});


like $result, qr/name="foo" \s+ value="value-foo"/xms;
like $result, qr/name="bar" \s+ value=""/xms;
like $result, qr/name="baz" \s+ value="value-bar"/xms;

