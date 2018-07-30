use strict;
use warnings;
use utf8;
use Test::More tests => 1 + 1 + 2;
use Test::NoWarnings;
use Test::Warn;

warnings_like {
	require HTML::Hyphenate;
} [
], 'Warned about unescaped left brace in TeX::Hyphen';


my $hyphenator = HTML::Hyphenate->new();

$hyphenator->default_lang(q{da-DK});

is( $hyphenator->hyphenated(q{<svg><title>Selvbetjeningen</title></svg>}),
    q{<svg><title>Selv­be­tje­nin­gen</title></svg>}, q{RT#125900} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
