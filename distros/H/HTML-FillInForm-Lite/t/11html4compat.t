#!perl -w

use strict;
use Test::More tests => 1;

use HTML::FillInForm::Lite;

my $fif = HTML::FillInForm::Lite->new;

unlike $fif->fill(
	\'<input name="foo">',
	{ foo => 'bar' },
), qr{/};
