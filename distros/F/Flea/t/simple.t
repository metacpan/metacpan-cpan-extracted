use Plack::Test;
use Flea;
use HTTP::Request::Common;
use Test::More;
use Plack::Builder;

my $app = builder {
    enable 'HTTPExceptions';
    bite {
        get '^/?$' {
            text 'hello, world!';
        }
        get '^/foo$' {
            my $r = request(shift);
            text $r->path_info;
        }
        post '^/bar$' {
            text 'post';
        }
    }
};

test_psgi $app, sub {
    my $r = shift->(GET '/');
    ok $r->is_success;
    is $r->content_type, 'text/plain';
    is $r->content, 'hello, world!';
};

test_psgi $app, sub {
    my $r = shift->(GET '/foo');
    ok $r->is_success;
    is $r->content, '/foo';
};

test_psgi $app, sub {
    my $r = shift->(POST '/bar');
    is $r->content, 'post';
};

test_psgi $app, sub {
    my $r = shift->(GET '/not-found');
    is $r->code, 404;
};

test_psgi $app, sub {
    my $r = shift->(POST '/foo');
    is $r->code, 405;
};

done_testing;
