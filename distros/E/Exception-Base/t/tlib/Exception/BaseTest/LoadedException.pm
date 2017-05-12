package Exception::BaseTest::LoadedException;

our $VERSION = 0.03;

use Exception::Base (
    'Exception::BaseTest::LoadedException' => {
        has => [ 'myattr' ],
    },
);

1;
