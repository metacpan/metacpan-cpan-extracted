# vim:set filetype=perl sw=4 et:

#########################

my @encodings;

BEGIN {
    @encodings = qw(uhmal UHMAL
                    tlhIngan tlhingan TLHINGAN
                    XIFAN XIFANZ xifan xifanz);
}

use Test::More tests => (1
                         + @encodings*@encodings
                         + @encodings*@encodings*5
                         + @encodings*@encodings);
use Carp;
use strict;

BEGIN {use_ok 'Lingua::Klingon::Recode', 'recode'; }

my($from, $to);

# test a simple word
my %word = (
    'uhmal' => 'uhmal',
    'UHMAL' => 'UHMAL',
    'tlhIngan' => 'tlhIngan',
    'tlhingan' => 'tlhingan',
    'TLHINGAN' => 'TLHINGAN',
    'XIFAN' => 'XIFAN',
    'XIFANZ' => 'XIFAN',
    'xifan' => 'xifan',
    'xifanz' => 'xifan',
);

for $from (@encodings) {
    for $to (@encodings) {
        # diag "Testing $from -> $to";
        is(recode($from, $to, $word{$from}), $word{$to}, "[$from] '$word{$from}' => [$to] '$word{$to}'");
    }
}

# Some more words
my @words = (
    {
        'uhmal'    => 'kam',
        'UHMAL'    => 'KAM',
        'tlhIngan' => 'mang',
        'tlhingan' => 'mang',
        'TLHINGAN' => 'MANG',
        'XIFAN'    => 'MAF',
        'XIFANZ'   => 'MAF',
        'xifan'    => 'maf',
        'xifanz'   => 'maf',
    },
    {
        'uhmal'    => 'kamgnk',
        'UHMAL'    => 'KAMGNK',
        'tlhIngan' => 'mangHom',
        'tlhingan' => 'manghom',
        'TLHINGAN' => 'MANGHOM',
        'XIFAN'    => 'MAFHOM',
        'XIFANZ'   => 'MAFHOM',
        'xifan'    => 'mafhom',
        'xifanz'   => 'mafhom',
    },
    {
        'uhmal'    => 'kalfnk',
        'UHMAL'    => 'KALFNK',
        'tlhIngan' => 'manghom',
        'tlhingan' => 'manghom',
        'TLHINGAN' => 'MANGHOM',
        'XIFAN'    => 'MANGOM',
        'XIFANZ'   => 'MANGOM',
        'xifan'    => 'mangom',
        'xifanz'   => 'mangom',
    },
    {
        'uhmal'    => 'kamfnk',
        'UHMAL'    => 'KAMFNK',
        'tlhIngan' => 'mangghom',
        'tlhingan' => 'mangghom',
        'TLHINGAN' => 'MANGGHOM',
        'XIFAN'    => 'MAFGOM',
        'XIFANZ'   => 'MAFGOM',
        'xifan'    => 'mafgom',
        'xifanz'   => 'mafgom',
    },
    {
        'uhmal'    => 'qep',
        'UHMAL'    => 'QEP',
        'tlhIngan' => 'Qeq',
        'tlhingan' => 'qeq',
        'TLHINGAN' => 'QEQ',
        'XIFAN'    => 'QEK',
        'XIFANZ'   => 'QEK',
        'xifan'    => 'qek',
        'xifanz'   => 'qek',
    },
);

my $word;
for $word (@words) {
    # diag "\nTesting word $word->{'tlhIngan'}\n";
    for $from (@encodings) {
        SKIP: {
            # Skip 'manghom' and 'Qeq' tests for the lossy tlhingan and
            # TLHINGAN encodings; due to case-smashing, these tests can never
            # work.
            skip "case-smashing loses information", scalar(@encodings)
                if (($from eq 'tlhingan' or $from eq 'TLHINGAN')
                    &&
                    ($word->{'tlhIngan'} eq 'manghom' or $word->{'tlhIngan'} eq 'Qeq'));

            for $to (@encodings) {
                # diag "Testing $from -> $to";
                is(recode($from, $to, $word->{$from}), $word->{$to}, "[$from] '$word->{$from}' => [$to] '$word->{$to}'");
            }
        }
    }
}

# test a phrase with embedded whitespace and punctuation
# (but no 'q' or 'Q')
my %phrase = (
    'uhmal' => 'uhmal gnj daiauzaz? ghsjag, uhmal gnj whiaujagcvz',
    'UHMAL' => 'UHMAL GNJ DAIAUZAZ? GHSJAG, UHMAL GNJ WHIAUJAGCVZ',
    'tlhIngan' => "tlhIngan Hol Dajatlh'a'? HISlaH, tlhIngan Hol vIjatlhlaHchu'",
    'tlhingan' => "tlhingan hol dajatlh'a'? hislah, tlhingan hol vijatlhlahchu'",
    'TLHINGAN' => "TLHINGAN HOL DAJATLH'A'? HISLAH, TLHINGAN HOL VIJATLHLAHCHU'",
    'XIFAN' => "XIFAN HOL DAJAX'A'? HISLAH, XIFAN HOL VIJAXLAHCU'",
    'XIFANZ' => 'XIFAN HOL DAJAXZAZ? HISLAH, XIFAN HOL VIJAXLAHCUZ',
    'xifan' => "xifan hol dajax'a'? hislah, xifan hol vijaxlahcu'",
    'xifanz' => 'xifan hol dajaxzaz? hislah, xifan hol vijaxlahcuz',
);

for $from (@encodings) {
    for $to (@encodings) {
        # diag "Testing $from -> $to";
        is(recode($from, $to, $phrase{$from}), $phrase{$to}, "[$from] '$phrase{$from}' => [$to] '$phrase{$to}'");
    }
}

