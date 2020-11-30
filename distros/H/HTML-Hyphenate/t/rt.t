use strict;
use warnings;
use utf8;
use Test::More tests => 1 + 2;
use Test::NoWarnings;

use HTML::Hyphenate;
my $hyphenator = HTML::Hyphenate->new();

$hyphenator->default_lang(q{da-DK});

is( $hyphenator->hyphenated(q{Selvbetjeningen}),
    q{Selv­be­tje­nin­gen}, q{RT#64114} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
