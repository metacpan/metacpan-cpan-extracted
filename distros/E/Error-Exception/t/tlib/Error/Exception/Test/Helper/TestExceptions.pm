package Error::Exception::Test::Helper::TestExceptions;

use strict;
use warnings;

use Error::Exception;

use Exception::Class (
    'Error::Exception::Test::NoFields' => {
        isa         => 'Error::Exception',
        description => 'Testing exception with no fields',
    },
    'Error::Exception::Test::OneField' => {
        isa         => 'Error::Exception',
        fields      => [ 'firstfield' ],
        description => 'Testing exception with no fields',
    },
);

1;
