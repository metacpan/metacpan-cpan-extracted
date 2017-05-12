use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';
use Cache;
use HTTP::Session2::ServerStore;

sub scenario {
    local %Cache::STORE = ();
    subtest(@_);
}
sub step { note $_[0]; goto $_[1] }
sub empty_res { [200, [], []] }

scenario 'First request' => sub {
    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ServerStore->new(
            env => {
            },
            get_store => sub { Cache->new() },
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
        $session = HTTP::Session2::ServerStore->new(
            env => {
            },
            get_store => sub { Cache->new() },
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
        my ($sess_id) = ($res->[1]->[1] =~ qr{\Ahss_session=([^;]*); path=/; HttpOnly\z});
        ok $sess_id;
        is $res->[1]->[2], 'Set-Cookie';
        like $res->[1]->[3], qr{\AXSRF-TOKEN=([^;]*); path=/\z};
        my $xsrf_token = $1;

        is $Cache::STORE{$sess_id}{foo}, 'bar', 'stored';
    };
} or die;

scenario 'Login' => sub {
    Cache->new->set(SsEeSsIiOoNn => { foo => 'bar' });

    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ServerStore->new(
            env => {
                HTTP_COOKIE => 'hss_session=SsEeSsIiOoNn',
            },
            get_store => sub { Cache->new() },
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
        isnt $sess_id, 'SsEeSsIiOoNn';
        is $res->[1]->[2], 'Set-Cookie';
        like $res->[1]->[3], qr{\AXSRF-TOKEN=([^;]*); path=/\z};
        my $xsrf_token = $1;

        is_deeply $Cache::STORE{$sess_id}, {
            foo => 'bar',
            user_id => 5963,
        };
    };
} or die;

scenario 'In a login session' => sub {
    Cache->new->set(SsEeSsIiOoNn => { user_id => 5963 });

    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ServerStore->new(
            env => {
                HTTP_COOKIE => 'hss_session=SsEeSsIiOoNn',
            },
            get_store => sub { Cache->new() },
            secret => 's3cret',
        );
    };
    step 'server -> store: set more data' => sub {
        $session->set('foo' => 'bar');
    };
    step 'server -> client: response without session/xsrf cookie' => sub {
        my $res = empty_res();
        $session->finalize_psgi_response($res);
        is 0+@{$res->[1]}, 0;

        is_deeply $Cache::STORE{SsEeSsIiOoNn}, {
            foo => 'bar',
            user_id => 5963,
        };
    };
};

scenario 'Logout' => sub {
    Cache->new->set(SsEeSsIiOoNn => { foo => 'bar' });

    my $session;
    step 'client -> server: request without cookie' => sub {
        $session = HTTP::Session2::ServerStore->new(
            env => {
                HTTP_COOKIE => 'hss_session=SsEeSsIiOoNn',
            },
            store => Cache->new(),
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

        is_deeply \%Cache::STORE, {};
    };
};

done_testing;

