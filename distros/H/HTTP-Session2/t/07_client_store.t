use strict;
use warnings;
use utf8;
use Test::More 0.96;
use HTTP::Session2::ClientStore;
use Cookie::Baker;
use Plack::Request;

sub make_cookie_header_from_psgi_response {
    my $res = shift;
    my $x = sub {
        my $h = shift;
        if ($h =~ /\A([^;]*);/) {
            $1;
        } else {
            die "Invalid http header: $h";
        }
    };
    return join(';', $x->($res->[1]->[1]), $x->($res->[1]->[3]));
}

subtest 'get/set/remove' => sub {
    my $client = HTTP::Session2::ClientStore->new(
        env => {},
        secret => 'secret',
    );
    is $client->get('foo'), undef;
    $client->set('foo', 'bar');
    is $client->get('foo'), 'bar';
    is $client->remove('foo'), 'bar';
};

subtest 'validate_token' => sub {
    my $header = do {
        my $session = HTTP::Session2::ClientStore->new(
            env => {
            },
            secret => 'secret',
        );
        $session->set(x => 1);
        my $res = [200,[],[]];
        $session->finalize_psgi_response($res);
        is 0+@{$res->[1]}, 4;
        make_cookie_header_from_psgi_response($res);
    };

    subtest 'bad' => sub {
        my $env = +{
            HTTP_COOKIE => $header,
        };
        my $client = HTTP::Session2::ClientStore->new(
            env                    => $env,
            secret                 => 'secret',
        );
        my $req = Plack::Request->new($env);
        ok !$client->validate_xsrf_token('');
    };

    subtest 'good' => sub {
        my $env = +{
            HTTP_COOKIE => $header,
        };
        my $req = Plack::Request->new($env);
        $env->{'QUERY_STRING'} = 'XSRF-TOKEN=' . $req->cookies->{'XSRF-TOKEN'};
        my $client = HTTP::Session2::ClientStore->new(
            env                    => $env,
            secret                 => 'secret',
        );
        ok $client->validate_xsrf_token($req->cookies->{'XSRF-TOKEN'});
    };
};

subtest 'ignore_old' => sub {
    my $t1 = time();
    my $session_data = do {
        my $client = HTTP::Session2::ClientStore->new(
            env => {},
            secret => 'secret',
        );
        $client->set(x => 3);
        my $res = [200,[],[]];
        $client->finalize_psgi_response($res);
        $res->[1]->[1] =~ /hss_session=([^;]+)/;
        $1;
    };
    subtest 'ignore_old disabled' => sub {
        my $client = HTTP::Session2::ClientStore->new(
            env => {
                HTTP_COOKIE => "hss_session=${session_data}",
            },
            secret => 'secret',
            ignore_old => $t1-86400,
        );
        is $client->get('x'), 3;
    };
    subtest 'ignore_old enabled' => sub {
        my $client = HTTP::Session2::ClientStore->new(
            env => {
                HTTP_COOKIE => "hss_session=${session_data}",
            },
            secret => 'secret',
            ignore_old => $t1+86400,
        );
        is $client->get('x'), undef;
    };
};

done_testing;

