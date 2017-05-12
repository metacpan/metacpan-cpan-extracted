# $Id: 1-match.t,v 1.3 2002/08/13 21:38:33 crenz Exp $

use strict;
use Test::More tests => 6;
use Lingua::ZH::CEDICT;

my $dict = Lingua::ZH::CEDICT->new();

SKIP: {
    skip "Not yet implemented", 6;

    skip "These checks require perl >= 5.8.0", 6 if ($] < 5.008);

    eval { $dict->init(); };
    skip "Cannot load CEDICT.store: $@", 6 if ($@);

    require utf8;

    $dict->startFind('house');
    my $m = $dict->find();
    ok(ref($m), "Search for 'house'");
    ok(utf8::is_utf8($m->[0]), 'Traditional characters are flagged UTF-8');
    ok(utf8::is_utf8($m->[1]), 'Simplified characters are flagged UTF-8');
    $m = $dict->find();
    ok(ref($m), "Further search for 'house'");
    ok(utf8::is_utf8($m->[0]), 'Traditional characters are flagged UTF-8');
    ok(utf8::is_utf8($m->[1]), 'Simplified characters are flagged UTF-8');
}

