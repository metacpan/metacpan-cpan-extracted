#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('HTML::Template::Compiled::Plugin::I18N::DefaultTranslator');
}

my $escape_ref = HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->get_escape();
is(
    ref $escape_ref,
    'CODE',
    'get the default escape code reference',
);
is(
    $escape_ref->(10),
    10,
    'default escape of a defined value',
);
is(
    $escape_ref->(),
    'undef',
    'default escape of undef',
);
HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->set_escape(
    sub {return},
);
$escape_ref = HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->get_escape();
is(
    $escape_ref->(10),
    undef,
    'escape of a defined value must be undef now',
);
