# $Id: 1-match.t,v 1.3 2002/08/13 21:38:33 crenz Exp $

use strict;
use Test::More tests => 3;
use Lingua::ZH::CEDICT;

my $dict = Lingua::ZH::CEDICT->new();

SKIP: {
    eval { require Storable; };
    skip "Storable not installed", 3 if ($@);

    eval { $dict->init(); };
    skip "Cannot load CEDICT.store: $@", 3 if ($@);

    ok(1, "Init stored dictionary");
    $dict->startMatch('house');
    my $m = $dict->match();
    ok(ref($m), "Search for 'house'");
    ok(ref($m), "Further search for 'house'");
}

