# A little plack app for testing HTTP::AnyUA

# When a request is made, the environment will be sent back to the test which will assert that the
# request was made correctly.

use Plack::Builder;
use Util qw(send_env);

builder {

    mount '/create-document' => sub {
        my $env = shift;
        send_env($env);
        [201, ['Content-Type' => 'text/plain'], ['created document']];
    };

    mount '/get-document' => sub {
        my $env = shift;
        send_env($env);
        [200, ['Content-Type' => 'text/plain', 'x-foo' => 'bar'], ['this is a document']];
    };

    mount '/modify-document' => sub {
        my $env = shift;
        send_env($env);
        [204, [], ['']];
    };

    mount '/foo' => sub {
        [302, ['Content-Type' => 'text/plain', 'Location' => '/bar'], ['the thing you seek is not here']];
    };
    mount '/bar' => sub {
        [301, ['Content-Type' => 'text/plain', 'Location' => '/baz'], ['not here either']];
    };
    mount '/baz' => sub {
        my $env = shift;
        send_env($env);
        [200, ['Content-Type' => 'text/plain'], ['you found it']];
    };

    mount '/' => sub {
        [200, ['Content-Type' => 'text/plain'], ['this is a test server']];
    };

}

