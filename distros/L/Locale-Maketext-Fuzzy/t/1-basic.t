#!/usr/bin/perl -w

use strict;
use Test::More tests => 15;

package MyApp::L10N;
use Test::More;
use Locale::Maketext::Fuzzy;
use_ok(base => 'Locale::Maketext::Fuzzy');

package MyApp::L10N::de;
use vars qw/@ISA %Lexicon/;

@ISA = 'MyApp::L10N';
%Lexicon = (
    # Exact match should always be preferred if possible
    "0 camels were released."
	=> "Exact match",
    # Fuzzy match candidate
    "[*,_1,camel was,camels were] released."
	=> "[quant,_1,Kamel wurde,Kamele wurden] freigegeben.",
    # This could also match fuzzily, but is less preferred
    "[_2] released[_1]"
	=> "[_1][_2] ist frei[_1]",
);

package main;

################################################################

ok(my $lh = MyApp::L10N->get_handle('de'), 'get_handle');

is($lh->override_maketext, 0,		'override_maketext() is initially 0');
is($lh->override_maketext(0), 0,	'override_maketext(0)');
is($lh->override_maketext(1), 1,	'override_maketext(1)');
is($lh->override_maketext(undef), 0,	'override_maketext(undef) is 0');
is($lh->override_maketext(-1), 1,	'override_maketext(-1) is 1');
is($lh->override_maketext, 1,		'override_maketext() is now 1');

################################################################

is(
    $lh->maketext('0 camels were released.'),
    'Exact match',
    'exact match',
);

is(
    $lh->maketext('1 camel was released.'),
    '1 Kamel wurde freigegeben.',
    'fuzzy match - singular',
);

is(
    $lh->maketext('2 camels were released.'),
    '2 Kamele wurden freigegeben.',
    'fuzzy match - plural',
);

is(
    $lh->maketext('3 released.'),
    '3 Kamele wurden freigegeben.',
    'fuzzy match - ignore parameters',
);

is(
    $lh->maketext('[*,_1,camel was,camels were] released.', 4),
    '4 Kamele wurden freigegeben.',
    'exact match on the bracketed entry',
);

is(
    $lh->maketext('[Perl] released!'),
    '![Perl] ist frei!',
    'fuzzy match on the broader candidate',
);

is(
    eval { $lh->maketext('Square [bracket]!') },
    'Square [bracket]!',
    'no interpolation on failed matches',
);

################################################################

1;
