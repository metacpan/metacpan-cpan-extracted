use strict;

use Test::Exception;
use Test::More;
use HTTP::Exception;

# do we play nicely with other user defined exception?

use Exception::Class ('User::Defined::Exception' => {});

throws_ok sub { User::Defined::Exception->throw; }, 'User::Defined::Exception';

eval { User::Defined::Exception->throw; };
ok !defined HTTP::Exception->caught        , 'HTTP::Exception not caught';
ok defined User::Defined::Exception->caught, 'User::Defined::Exception caught';
ok defined Exception::Class->caught        , 'Exception::Class caught';

eval { HTTP::Exception::200->throw; };
ok defined HTTP::Exception->caught        , 'HTTP::Exception caught';
ok !defined User::Defined::Exception->caught, 'User::Defined::Exception not caught';
ok defined Exception::Class->caught        , 'Exception::Class caught';

done_testing;