use strict;
use Test::More;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

my $psgi_app = sub { 
    return [
        200,
        [ "Content-Type", "text/plain" ],
        [ "Hi" ],
    ];
};

{
    my $guard = LWP::Protocol::PSGI->register($psgi_app, host => "localhost");
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("http://localhost:5000/");
    is $res->content, "Hi";
}

{
    my $guard = LWP::Protocol::PSGI->register($psgi_app, host => "localhost:5000");
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("http://localhost:5000/");
    is $res->content, "Hi";
}

done_testing;
