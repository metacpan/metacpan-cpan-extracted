use strict;

use Test::More;
use HTTP::Exception;
use HTTP::Status;

# this is more or less testing, whether the is_ subs work
# since inheritance should work, i don't bother testing the statusname-classes

my @tests = (100,200,300,400,500);

for my $statuscode (@tests) {
    my $e = HTTP::Exception->new($statuscode);
    is  $e->is_info,
        !!HTTP::Status::is_info($statuscode),
        "$statuscode is ". ($e->is_info ? '' : 'not ') .'an info';

    is  $e->is_success,
        !!HTTP::Status::is_success($statuscode),
        "$statuscode is ". ($e->is_success ? '' : 'not ') .'a success';

    is  $e->is_redirect,
        !!HTTP::Status::is_redirect($statuscode),
        "$statuscode is ". ($e->is_redirect ? '' : 'not ') .'a redirect';

    is  $e->is_error,
        !!HTTP::Status::is_error($statuscode),
        "$statuscode is ". ($e->is_error ?  '' : 'not ') .'an error';

    is  $e->is_client_error,
        !!HTTP::Status::is_client_error($statuscode),
        "$statuscode is ". ($e->is_client_error ? '' : 'not ') .'a clienterror';

    is  $e->is_server_error,
        !!HTTP::Status::is_server_error ($statuscode),
        "$statuscode is ". ($e->is_server_error ? '' : 'not ') .'a servererror';
}

done_testing;