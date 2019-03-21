use strict;
use warnings;
use Test::More;

BEGIN {
    %ENV = (
        PLAIN    => 'false',
        OPTION_C => 'c',
    );
}
use Dotenv -load => 't/env/plain.env';

is_deeply(
    \%ENV,
    {
        PLAIN    => 'false',    # not modified
        OPTION_A => 1,
        OPTION_B => 2,
        OPTION_C => 'c',        # not modified
        OPTION_D => 4,
        OPTION_E => 5,
    },

    'load .env file at require time'
);

done_testing;
