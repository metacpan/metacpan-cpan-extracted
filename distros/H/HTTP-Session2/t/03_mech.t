use strict;
use warnings;
use utf8;
use Test::More;
use Test::WWW::Mechanize::PSGI;
use lib 't/lib/';
use Cache;
use HTTP::Session2::ServerStore;
use HTTP::Session2::ClientStore;

sub SUCCESS() { [200, [], ['OK']] }

our $SESSION_FACTORY;

my $app = sub {
    my $env = shift;
    my $session = $SESSION_FACTORY->($env);
    note "$env->{REQUEST_METHOD} $env->{PATH_INFO} @{[ $session->id]}";

    if ($env->{REQUEST_METHOD} eq 'POST') {
        my $token = $env->{HTTP_X_XSRF_TOKEN};
        unless ($session->validate_xsrf_token($token)) {
            note 'XSRF detected';
            return [
                403, [], []
            ];
        }
    }

    my $res = sub {
        if ($env->{PATH_INFO} eq '/') {
            return SUCCESS;
        } elsif ($env->{PATH_INFO} eq '/wishlist') {
            # User can add wishlist without login.
            if ($env->{REQUEST_METHOD} eq 'GET') {
                my $wishlist = $session->get('wishlist') || [];
                return [200, [], [join(',', @$wishlist)]];
            } elsif ($env->{REQUEST_METHOD} eq 'POST') {
                my $wishlist = $session->get('wishlist') || [];
                push @$wishlist, $env->{QUERY_STRING};
                $session->set('wishlist', $wishlist);
                return SUCCESS;
            } else {
                die "ABORT"
            }
        } elsif ($env->{PATH_INFO} eq '/account/login') {
            $session->regenerate_id();
            $session->set('user', $env->{QUERY_STRING});
            return SUCCESS;
        } elsif ($env->{PATH_INFO} eq '/account/logout') {
            $session->expire();
            return [302, [Location => '/'], []];
        } elsif ($env->{PATH_INFO} eq '/my/name') {
            my $user = $session->get('user');
            if (defined $user) {
                return [200, [], [$user]];
            } else {
                return [403, [], []];
            }
            return SUCCESS;
        } else {
            return [404, [], []];
        }
    }->();
    $session->finalize_psgi_response($res);
    return $res;
};

for my $session_factory (\&server_session, \&client_session) {
    note "------ factory";

    local $SESSION_FACTORY = $session_factory;
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $app, max_redirect => 0);
    $mech->get_ok('/');
    $mech->post_ok('/wishlist?foo');
    $mech->get_ok('/wishlist');
    $mech->content_is('foo');
    $mech->post('/wishlist?bar');
    is $mech->status, 403;
    $mech->default_headers->header('X-XSRF-TOKEN', xsrf_token($mech));
    $mech->post_ok('/wishlist?bar');
    $mech->get_ok('/wishlist');
    $mech->content_is('foo,bar');
    $mech->post_ok('/account/login?john');
    $mech->get_ok('/wishlist', 'Wishlist is still available');
    $mech->content_is('foo,bar');
    $mech->post('/wishlist?baz');
    is $mech->status, 403, 'xsrf token was changed, too';
    $mech->default_headers->header('X-XSRF-TOKEN', xsrf_token($mech));
    $mech->post_ok('/wishlist?baz');
    $mech->get_ok('/wishlist', 'Wishlist is still available');
    $mech->content_is('foo,bar,baz');
    $mech->get_ok('/my/name');
    $mech->content_is('john');

    is cookie_count($mech), 2;
    $mech->post('/account/logout?john');
    is $mech->status, 302;
    is cookie_count($mech), 0;
};

done_testing;

sub cookie_count {
    my $mech = shift;
    my $cnt = 0;
    $mech->cookie_jar->scan(sub { $cnt++ });
    return $cnt;
}

sub xsrf_token {
    my $mech = shift;
    $mech->cookie_jar->{COOKIES}->{'localhost.local'}->{'/'}->{'XSRF-TOKEN'}->[1];
}

sub server_session {
    my $env = shift;
    HTTP::Session2::ServerStore->new(
        env => $env,
        get_store => sub { Cache->new() },
        secret => 's3cret',
    );
}

sub client_session {
    my $env = shift;
    HTTP::Session2::ClientStore->new(
        env => $env,
        secret => 's3cret',
    );
}
