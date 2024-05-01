use strict;
use Test::More;

require './t/parse-dir.pm';

testRequiredMethods(
    'Lemonldap::NG::Portal::UserDB',
    [ qw(
          init
          getUser
          setSessionInfo
          setGroups
        )
    ],
    [ qw(
          Combination
          Custom
          Proxy
        )
    ],
);

done_testing();
