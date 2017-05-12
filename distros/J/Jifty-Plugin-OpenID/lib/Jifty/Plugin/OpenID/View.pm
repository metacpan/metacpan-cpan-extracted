package Jifty::Plugin::OpenID::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::OpenID::View - Login and create pages for OpenID plugin

=head1 DESCRIPTION

The view class for L<Jifty::Plugin::OpenID>.  Provides login and create pages.

=cut

template 'openid/login' => page {
    { title is _("Login with your OpenID") }
    my ($action, $next) = get('action', 'next');

    div {
        unless ( Jifty->web->current_user->id ) {
            div {
                attr { id => 'openid-login' };
                outs(
                    p {
                        em {
                            _(  qq{If you have a Livejournal or other OpenID account, you don\'t even need to sign up. Just log in.}
                            );
                        }
                    }
                );
                Jifty->web->form->start( call => $next );
                render_action($action);
                form_submit(
                    label  => _("Go for it!"),
                    submit => $action
                );
                Jifty->web->form->end;
            };
        }
        else {
            outs( _("You already logged in.") );
        }
    }
};

template 'openid/create' => page {
    title is _('Set your username');
    my ( $action, $next ) = get( 'action', 'next' );

    p {
        outs(
            _(  'We need you to set a username or quickly check the one associated with your OpenID. Your username is what other people will see when you ask questions or make suggestions'
            )
        );
    };
    p {
        outs(
            _(  'If the username provided conflicts with an existing username or contains invalid characters, you will have to give us a new one.'
            )
        );
    };
    Jifty->web->form->start( call => $next , name => 'openid-user-create' );
    my $openidSP = Jifty->web->session->get('ax_mapping');
    if ($openidSP) {
        foreach my $param (keys %$openidSP) {
            # keep get to use validation
            render_param($action, $param, default_value => get($param) );
            div { class is "form_field";
                span { class is "hints";
                    outs( _( 'A link to confirm this email will be sent to receive later notifications.' ) );
                }
            } if ($param eq 'email');
        }
    }
    else {
        render_action($action);
        };
    form_submit( label => _('Continue'), submit => $action );
    Jifty->web->form->end;
};

# optionnal fragment to add direct links to Google, Yahoo,
# MyOpenID login

template 'openid/wayf' => sub {
    my ( $self, $return_to ) = @_;
    div { attr { class => ''; };
        form {
            my $google = new_action( class => 'AuthenticateOpenID', moniker => 'authenticateopenid' );
            render_param($google, 'openid', render_as => 'hidden', default_value => 'www.google.com/accounts/o8/id');
            render_param($google, 'ax_param', render_as => 'hidden', default_value => "openid.ns.ax=http://openid.net/srv/ax/1.0&openid.ax.mode=fetch_request&openid.ax.type.email=http://axschema.org/contact/email&openid.ax.type.firstname=http://axschema.org/namePerson/first&openid.ax.type.lastname=http://axschema.org/namePerson/last&openid.ax.required=firstname,lastname,email");
            render_param($google, 'ax_mapping', render_as => 'hidden', default_value => "{ 'email': 'value.email', 'name': 'value.firstname value.lastname' }");
            render_param($google, 'ax_values', render_as => 'hidden', default_value => "value.email,value.firstname,value.lastname" );
            render_param($google,'return_to', render_as => 'hidden', default_value => '/openid/verify_and_login');
            img { src is '/static/oidimg/FriendConnect.gif'; };
            outs_raw(
                Jifty->web->return(
                as_link => 1,
                to => $return_to,
                label => _("Sign in with your Google Account"),
                submit => $google
                ));
        };
        form {
            my $yahoo = new_action( class => 'AuthenticateOpenID', moniker => 'authenticateopenid' );
            render_param($yahoo, 'openid', render_as => 'hidden', default_value => 'me.yahoo.com');
            render_param($yahoo, 'ax_param', render_as => 'hidden', default_value => "openid.ns.ax=http://openid.net/srv/ax/1.0&openid.ax.mode=fetch_request&openid.ax.type.email=http://axschema.org/contact/email&openid.ax.type.fullname=http://axschema.org/namePerson&openid.ax.required=fullname,email");
            render_param($yahoo, 'ax_mapping', render_as => 'hidden', default_value => "{ 'email': 'value.email', 'name': 'value.fullname' }");
            render_param($yahoo, 'ax_values', render_as => 'hidden', default_value => "value.email,value.fullname" );
            render_param($yahoo,'return_to', render_as => 'hidden', default_value => '/openid/verify_and_login');
            img { src is '/static/oidimg/yfavicon.gif'; };
            outs_raw(
                Jifty->web->return(
                as_link => 1,
                to => $return_to,
                label => _("Sign in with your Yahoo account"),
                submit => $yahoo
                ));
        };
        form {
            my $myoid = new_action( class => 'AuthenticateOpenID', moniker => 'authenticateopenid' );
            render_param($myoid, 'openid', render_as => 'hidden', default_value => 'www.myopenid.com');
            render_param($myoid, 'ax_param', render_as => 'hidden', default_value => "openid.ns.ax=http://openid.net/srv/ax/1.0&openid.ax.mode=fetch_request&openid.ax.type.email=http://schema.openid.net/contact/email&openid.ax.type.nickname=http://schema.openid.net/namePerson/friendly&openid.ax.required=nickname,email");
            render_param($myoid, 'ax_mapping', render_as => 'hidden', default_value => "{ 'email': 'value.email.1', 'name': 'value.nickname.1' }");
            render_param($myoid, 'ax_values', render_as => 'hidden', default_value => "value.email.1,value.nickname.1" );
            render_param($myoid,'return_to', render_as => 'hidden', default_value => '/openid/verify_and_login');
            img { src is '/static/oidimg/myopenid.png'; };
            outs_raw(
                Jifty->web->return(
                as_link => 1,
                to => $return_to,
                label => _("Sign in with your MyOpenID Account"),
                submit => $myoid
                ));
        };
    };
};

1;
