use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

use HTTP::Response::Switch::HandlerDeclinedResponse ();

test 'throw method must throw exception' => sub {
    throws_ok
        { HTTP::Response::Switch::HandlerDeclinedResponse->throw }
        'HTTP::Response::Switch::HandlerDeclinedResponse';
};

run_me;
done_testing;
