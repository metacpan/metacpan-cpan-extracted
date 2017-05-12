use strict;

use Test::Exception;
use Test::More;
use HTTP::Exception;

{
    package My::HTTP::Exception;
    use base 'HTTP::Exception::200';

    sub code    { 999 }
    sub my_info { 'Interesting Info' }
    sub status_message { 'Interesting Message' }
}

throws_ok sub { My::HTTP::Exception->throw; },
    'My::HTTP::Exception' ;

ok defined My::HTTP::Exception->caught,
    'custom HTTP::Exception caught';

ok defined HTTP::Exception::200->caught,
    'custom HTTP::Exception caught with HTTP::Exception::200';

ok defined HTTP::Exception::OK->caught,
    'custom HTTP::Exception caught with HTTP::Exception::OK';

ok !defined HTTP::Exception::404->caught,
    'custom HTTP::Exception not caught with wrong HTTP::Exception::OK';

my $e = HTTP::Exception->caught;
ok defined $e,          'custom HTTP::Exception caught with HTTP::Exception';
is $e->code,            999, 'code overridden';
is $e->my_info,         'Interesting Info', 'additional sub exists';
is $e->status_message,  'Interesting Message', 'Status Message changed';
is $e->as_string,       'Interesting Message', 'as_string changed';

done_testing;