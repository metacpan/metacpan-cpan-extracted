package Foorum::Controller::Logon;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

sub login : Global {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/forum') if ( $c->user_exists );

    $c->stash->{template} = 'user/login.html';
    my $url_base = $c->req->base;
    $c->req->param( 'referer', $c->req->referer )
        if (not $c->req->param('referer')
        and $c->req->referer
        and $c->req->referer =~ /$url_base/
        and $c->req->referer !~ /login/ );
    return unless ( $c->req->method eq 'POST' );

    my $username = $c->req->param('username');
    $username =~ s/\W+//isg;
    my $email    = $c->req->param('email');
    my $password = $c->req->param('password');
    if ( not $username and $email ) {
        my $user = $c->model('DBIC::User')->get( { email => $email } );
        if ($user) {
            $username = $user->{username};
        } else {
            return $c->stash->{error} = 'ERROR_AUTH_FAILED';
        }
        $password = $c->req->param('email_password');
    }

    # check if we need captcha
    # for login password wrong more than 3 times, we create a captcha.
    my $mem_key = "captcha|login|username=$username";
    my $failure_login_times = $c->cache->get($mem_key) || 0;

    if ( $username and $password ) {

        my $can_login  = 0;
        my $captcha_ok = ( $failure_login_times > 2
                and $c->validate_captcha( $c->req->param('captcha') ) );
        $can_login = ( $failure_login_times < 3 or $captcha_ok );

        if ($can_login
            and $c->authenticate(
                { username => $username, password => $password }
            )
            ) {

            if (   $c->user->get('status') eq 'banned'
                or $c->user->get('status') eq 'blocked'
                or $c->user->get('status') eq 'terminated' ) {
                $c->logout;
                $c->detach( '/print_error', ['ERROR_ACCOUNT_CLOSED_STATUS'] );
            }

            # remember me
            if ( $c->req->param('remember_me') ) {
                $c->session_time_to_live(604800);  # 7 days = 24 * 60 * 60 * 7
            }

            # login_times++
            # if last_login_on is 3 hours ago, point++
            # YYY? need improvement
            my $point = $c->user->{point};
            $point++ if ( $c->user->{last_login_on} < time() - 3600 * 3 );
            $c->model('DBIC::User')->update_user(
                $c->user,
                {   login_times   => \'login_times + 1',    #'
                    point         => $point,
                    last_login_on => time(),
                    last_login_ip => $c->req->address,
                }
            );

            if ( length( $c->user->lang ) == 2 ) {
                $c->res->cookies->{lang} = { value => $c->user->lang };
                $c->stash->{lang} = $c->user->lang;
                $c->languages( [ $c->stash->{lang} ] );
            }

            # redirect
            my $referer = $c->req->param('referer') || '/';
            $c->res->redirect($referer);
        } else {
            $failure_login_times++;
            $c->cache->set( $mem_key, $failure_login_times, 600 ); # 10 minite
            $c->stash->{failure_login_times} = $failure_login_times;

            if ($can_login) {
                $c->stash->{error} = 'ERROR_AUTH_FAILED';
            } else {
                $c->stash->{error} = 'ERROR_CAPTCHA';
            }
        }
    } else {
        $c->stash->{error} = 'ERROR_ALL_REQUIRED';
    }
}

sub logout : Global {
    my ( $self, $c ) = @_;

    # log the user out
    $c->logout;

    $c->res->redirect('/');
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
