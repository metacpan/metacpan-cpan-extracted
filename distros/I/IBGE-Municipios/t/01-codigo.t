use strict;
use warnings;
use Test::More tests => 5;

use IBGE::Municipios;

is(
    IBGE::Municipios::codigo(),
    undef,
    'calling with no args returns undef'
);

is(
    IBGE::Municipios::codigo( 'Rio de Janeiro' ),
    undef,
    'calling with just the city returns undef'
);


is(
    IBGE::Municipios::codigo( undef, 'RJ' ),
    undef,
    'calling with just the state returns undef'
);


is(
    IBGE::Municipios::codigo( 'Rio de Janeiro', 'RJ' ),
    3304557,
    'calling with existing city/state returns proper code'
);

is(
    IBGE::Municipios::codigo( 'Rio de Janeiro', 'AL' ),
    undef,
    'calling with non-existant city/state returns undef'
);


