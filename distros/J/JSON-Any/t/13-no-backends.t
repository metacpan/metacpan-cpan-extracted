use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

require JSON::Any;

use Test::Without::Module qw(Cpanel::JSON::XS JSON::XS JSON::DWIW JSON JSON::PP JSON::Syck);

{
    local $ENV{JSON_ANY_ORDER};
    like(
        exception { JSON::Any->import },
        qr/Couldn't find a JSON package. Need Cpanel::JSON::XS, JSON::XS, JSON::PP, JSON or JSON::DWIW at/,
        'error lists all the default backends',
    );
}

{
    local $ENV{JSON_ANY_ORDER} = 'JSON';

    like(
        exception { JSON::Any->import },
        qr/Couldn't find a JSON package. Need JSON at/,
        'error only lists the single backend that was allowed in JSON_ANY_ORDER',
    );
}

{
    local $ENV{JSON_ANY_ORDER} = 'XS DWIW';

    like(
        exception { JSON::Any->import },
        qr/Couldn't find a JSON package. Need JSON::XS or JSON::DWIW at/,
        'error only lists the backends that were allowed in JSON_ANY_ORDER',
    );
}

done_testing;
