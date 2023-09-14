use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 qw(:no_end_test :all);

require JSON::Any;

use Test::Needs 'JSON::Syck';

use Test::Without::Module qw(Cpanel::JSON::XS JSON::XS JSON::DWIW JSON JSON::PP);

{
    local $ENV{JSON_ANY_ORDER};
    like(
        warning { JSON::Any->import },
        qr/Found deprecated package JSON::Syck. Please upgrade to Cpanel::JSON::XS, JSON::XS, JSON::PP, JSON or JSON::DWIW at/,
        'error lists all the default backends',
    );
}

{
    local $ENV{JSON_ANY_ORDER} = 'JSON Syck';

    like(
        warning { JSON::Any->import },
        qr/Found deprecated package JSON::Syck. Please upgrade to JSON at/,
        'error only lists the single backend that was allowed in JSON_ANY_ORDER',
    );
}

{
    local $ENV{JSON_ANY_ORDER} = 'XS DWIW Syck';

    like(
        warning { JSON::Any->import },
        qr/Found deprecated package JSON::Syck. Please upgrade to JSON::XS or JSON::DWIW at/,
        'error only lists the backends that were allowed in JSON_ANY_ORDER',
    );
}

done_testing;
