#!perl -T

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
}

my $loc = Locale::TextDomain::OO->new(
    filter => sub {
        my $text_ref = pop;
        ${$text_ref} = reverse ${$text_ref};
        return;
    },
);
{
    my $translation = 'dummy';
    $loc->run_filter(\$translation),
    is
        $translation,
        'ymmud',
        'reverse filtered';
}

$loc->filter(undef);
{
    my $translation = 'dummy';
    $loc->run_filter(\$translation),
    is
        $translation,
        'dummy',
        'not filtered';
}

$loc->filter(
    sub {
        my $text_ref = pop;
        ${$text_ref} = qq{"${$text_ref}"};
        return;
    },
);
{
    my $translation = 'dummy';
    $loc->run_filter(\$translation),
    is
        $translation,
        '"dummy"',
        'quote filtered';
}
