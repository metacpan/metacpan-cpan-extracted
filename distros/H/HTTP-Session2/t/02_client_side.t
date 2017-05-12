use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';
use HTTP::Session2::ClientStore;

sub scenario {
    subtest(@_);
}
sub step { note $_[0]; goto $_[1] }
sub empty_res { [200, [], []] }

scenario 'First request' => sub {
    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ClientStore->new(
            env => {
            },
            secret => 's3cret',
        );
    };
    step 'server -> client: response without cookie' => sub {
        my $res = empty_res();
        $session->finalize_psgi_response($res);
        is_deeply $res->[1], [];
    };
};

scenario 'Store something without login' => sub {
    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ClientStore->new(
            env => {
            },
            secret => 's3cret',
        );
    };
    step 'server -> store: save data' => sub {
        $session->set('foo' => 'bar');
    };
    step 'server -> client: response with session/xsrf cookie' => sub {
        my $res = empty_res();
        $session->finalize_psgi_response($res);
        is $res->[1]->[0], 'Set-Cookie';
        my ($session) = ($res->[1]->[1] =~ qr{\Ahss_session=([^;]*); path=/; HttpOnly\z});
        ok $session or diag $res->[1]->[1];
        is $res->[1]->[2], 'Set-Cookie';
        like $res->[1]->[3], qr{\AXSRF-TOKEN=([^;]*); path=/\z};
        my $xsrf_token = $1;

        note $session;
    };
};


scenario 'Login' => sub {
    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ClientStore->new(
            env => {
                HTTP_COOKIE => 'hss_session=1382835355%3A6e608b9e08d3f76a09ec8ddac36a2ae%3ABQkDAAAAAQoDYmFyAAAAA2Zvbw%3D%3D%3A62343563626434303633303330323837343561383030643531613666623237396233356132353138',
            },
            secret => 's3cret',
        );
    };
    step 'server -> server: regenerate_id' => sub {
        $session->regenerate_id();
    };
    step 'server -> store: save data' => sub {
        $session->set('user_id' => '5963');
    };
    step 'server -> client: response with session/xsrf cookie' => sub {
        my $res = empty_res();
        $session->finalize_psgi_response($res);
        is 0+@{$res->[1]}, 4;
        is $res->[1]->[0], 'Set-Cookie';
        my ($sess_id) = ($res->[1]->[1] =~ qr{\Ahss_session=([^;]*); path=/; HttpOnly\z});
        ok $sess_id;
        is $res->[1]->[2], 'Set-Cookie';
        like $res->[1]->[3], qr{\AXSRF-TOKEN=([^;]*); path=/\z};
        my $xsrf_token = $1;

        note $sess_id;
    };
};


scenario 'In a login session' => sub {
    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ClientStore->new(
            env => {
                HTTP_COOKIE => 'hss_session=1382835554%3Aeb197264fa8a8d9932b7547abda4525%3ABQkDAAAAAQoENTk2MwAAAAd1c2VyX2lk%3A63616161373262613236313366313436636363623863386361316231383663383937356433633137',
            },
            secret => 's3cret',
        );
    };
    step 'server -> store: set more data' => sub {
        $session->set('foo' => 'bar');
    };
    step 'server -> client: response without session/xsrf cookie' => sub {
        my $res = empty_res();
        $session->finalize_psgi_response($res);
        is 0+@{$res->[1]}, 4;
    };
};

scenario 'Logout' => sub {
    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ClientStore->new(
            env => {
                HTTP_COOKIE => 'hss_session=SsEeSsIiOoNn',
            },
            secret => 's3cret',
        );
    };
    step 'server -> server: expire' => sub {
        $session->expire();
    };
    step 'server -> client: response with expiration session/xsrf cookie' => sub {
        my $res = empty_res();
        $session->finalize_psgi_response($res);
        is $res->[1]->[0], 'Set-Cookie';
        like $res->[1]->[1], qr{\Ahss_session=; path=/; expires=[^;]+; HttpOnly\z};
        is $res->[1]->[2], 'Set-Cookie';
        like $res->[1]->[3], qr{\AXSRF-TOKEN=; path=/; expires=[^;]*\z};
        my $xsrf_token = $1;
    };
};

done_testing;

