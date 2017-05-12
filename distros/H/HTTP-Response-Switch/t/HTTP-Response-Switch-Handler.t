use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

use HTTP::Response ();
use Scalar::Util 'refaddr';

{
    package t::MyHandler;
    use Moose;
    with 'HTTP::Response::Switch::Handler';

    sub handle { }
}

test 'construction must fail without response object' => sub {
    throws_ok
        { t::MyHandler->new }
        qr/Attribute \(response\) is required/;
};

test 'response method must return response object' => sub {
    my $r = HTTP::Response->new;
    my $h = t::MyHandler->new( response => $r );
    is refaddr $r, refaddr $h->response;
};

test 'decline method must throw correct exception' => sub {
    my $r = HTTP::Response->new;
    throws_ok
        { t::MyHandler->new( response => $r)->decline }
        'HTTP::Response::Switch::HandlerDeclinedResponse';
};

run_me;
done_testing;
