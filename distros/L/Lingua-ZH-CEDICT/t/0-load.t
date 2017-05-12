# $Id: 0-load.t,v 1.3 2002/08/13 21:38:26 crenz Exp $

use strict;
use Test::More tests => 4;

use_ok('Lingua::ZH::CEDICT', 'use Lingua::ZH::CEDICT');

isa_ok(Lingua::ZH::CEDICT->new(source => 'Textfile'),
    "Lingua::ZH::CEDICT::Textfile");

SKIP: {
    eval { require Storable; };
    skip "Storable not installed", 1 if ($@);

    isa_ok(Lingua::ZH::CEDICT->new(source => 'Storable'),
        "Lingua::ZH::CEDICT::Storable");
}

SKIP: {
    eval { require Net::MySQL; };
    skip "Net::MySQL not installed", 1 if ($@);

    isa_ok(Lingua::ZH::CEDICT->new(source => 'MySQL'),
        "Lingua::ZH::CEDICT::MySQL");
}

__END__
