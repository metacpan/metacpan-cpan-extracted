use strict;
use warnings;
use Test::More;

%ENV = (
    PLAIN    => 'false',
    OPTION_C => 'c',
);

eval q{ use Dotenv 't/env/plain.env'; };
like( $@, qr{^Unknown action t/env/plain.env }, '`use Dotenv file` failed' );

is_deeply(
    \%ENV,
    {
        PLAIN    => 'false',    # not modified
        OPTION_C => 'c',        # not modified
    },
    '.env file not loaded'
);

done_testing;
