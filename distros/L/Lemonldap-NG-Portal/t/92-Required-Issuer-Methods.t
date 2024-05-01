use strict;
use Test::More;

require './t/parse-dir.pm';

testRequiredMethods(
    'Lemonldap::NG::Portal::Issuer',
    [ qw(
          run
          logout
        )
    ],
);

done_testing();
