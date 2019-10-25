use strict;
use Test::More;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use LWP::Simple;

my $psgi_app = sub {
    my $env = shift;
    return [
        200,
        [
            "Content-Type", "text/plain",
            "X-Foo" => "bar",
        ],
        [ "query=$env->{QUERY_STRING}" ],
    ];
};

LWP::Protocol::PSGI->register($psgi_app);

my $ua  = LWP::UserAgent->new;

sub verify {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $res = $ua->get("http://www.google.com/search?q=bar");
    is $res->content, "query=q=bar";
    is $res->header('X-Foo'), "bar";

    my $body = get "http://www.google.com/?q=x";
    is $body, "query=q=x";
}

subtest "when registered" => sub {
    verify;
};

LWP::Protocol::PSGI->unregister;

subtest "when unregistered" => sub {
 SKIP: {
        skip "needs internet access", 3 unless $ENV{AUTHOR_TESTING};

        my $res = $ua->get("http://www.google.com/search?q=bar");
        isnt $res->content, "query=q=bar";
        isnt $res->header('X-Foo'), "bar";

        my $body = get "http://www.google.com/?q=x";
        isnt $body, "query=q=x";
    }
};

LWP::Protocol::PSGI->register($psgi_app);

subtest "when reregistered" => sub {
    verify;
};

done_testing;
