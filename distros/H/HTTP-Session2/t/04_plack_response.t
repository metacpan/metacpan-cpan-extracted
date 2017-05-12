use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Response;

use HTTP::Session2::ClientStore;
use Test::WWW::Mechanize::PSGI;

{
    my $app = sub {
        my $env = shift;

        my $session = HTTP::Session2::ClientStore->new(env => $env, secret => 'yes. i am secret man.');
        $session->set(foo => 'bar');

        my $res = Plack::Response->new(200);
        $session->finalize_plack_response($res);
        return $res->finalize;
    };

    my $mech = Test::WWW::Mechanize::PSGI->new(app => $app, max_redirect => 0);
    $mech->get('/');
    note $mech->response->headers->as_string;
    is cookie_count($mech), 2;
}

{
    my $app = sub {
        my $env = shift;

        my $session = HTTP::Session2::ClientStore->new(env => $env, secret => 'yes. i am secret man.');
        $session->expire;

        my $res = Plack::Response->new(200);
        $session->finalize_plack_response($res);
        return $res->finalize;
    };

    my $mech = Test::WWW::Mechanize::PSGI->new(app => $app, max_redirect => 0);
    $mech->get('/');
    note $mech->response->headers->as_string;
    is cookie_count($mech), 0;
}

done_testing;

sub cookie_count {
    my $mech = shift;
    my $cnt = 0;
    $mech->cookie_jar->scan(sub { $cnt++ });
    return $cnt;
}
