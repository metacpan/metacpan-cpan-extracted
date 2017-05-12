package Gantry::Plugins::Uaf::Authenticate;

use 5.008;
use strict;
use warnings;

use Gantry::Utils::Crypt;
use Gantry::Plugins::Uaf::User;
use Data::Random qw(:all);

our $VERSION = '0.03';

sub new {
    my $proto = shift;
    my $gobj = shift;

    my $self;
    my $class = ref($proto) || $proto;
    my $app_rootp = $gobj->app_rootp || "";


    $self->{gantry} = $gobj;
    $self->{limit} = 3;
    $self->{timeout} = 3600;
    $self->{secret} = 'w3s3cR7';
    $self->{app_rootp} = $app_rootp || "";
    $self->{login_rootp} = $self->{app_rootp} . '/login';
    $self->{denied_rootp} = $self->{login_rootp} . '/denied';
    $self->{expired_rootp} = $self->{login_rootp} . '/expired';
    $self->{filter} = qr/^${app_rootp}\/(login|static|cookiecheck).*/;
    $self->{crypt} = Gantry::Utils::Crypt->new({'secret' => $self->{secret}});

    bless($self, $class);

    return $self;

}

sub is_valid($) {
    my ($self) = @_;

    my $ip;
    my $old_ip;
    my $access;
    my $needed;
    my $old_token;
    my $token = "";
    my $user = undef;

    $ip = $self->{gantry}->remote_ip;
    $token = ($self->{gantry}->get_cookies('_token_id_') || '') . '=';

    if (defined($token) and ($token ne '=')) {

        if ($self->{gantry}->session_lock()) {

            $old_ip = $self->{gantry}->session_retrieve('uaf_remote_ip') || '';
            $old_token = $self->{gantry}->session_retrieve('uaf_token') || '';

            # This should work for just about everything except a load
            # balancing, natted firewall. And yeah, they do exist.

            if (($token eq $old_token) and ($ip eq $old_ip)) {

                $user = $self->{gantry}->session_retrieve('uaf_user');
                $access = $user->attribute('last_access');
                $user->attribute('last_access', time());
                $self->{gantry}->session_update('uaf_user', $user);
                $user = undef if ($access  <  (time() - $self->{timeout}));

            }

            $self->{gantry}->session_unlock();

        }

    }

    return $user;

}

sub validate($$$) {
    my ($self, $username, $password) = @_;

    my $ip = "";
    my $salt = "";
    my $user = undef;

    $username = lc($username);
    $password = lc($password);
    $ip = $self->{gantry}->remote_ip;
    $salt = rand_chars(set => 'all', min => 5, max => 10);

    if (($username eq 'admin') and ($password eq 'admin')) {

        $user = Gantry::Plugins::Uaf::User->new($username);
        $user->attribute('login_attempts', 0);
        $user->attribute('last_access', time());
        $user->attribute('salt', $salt);
        $self->{gantry}->session_store('uaf_remote_ip', $ip);
        $self->{gantry}->session_update('uaf_user', $user);

    } elsif (($username eq 'demo') and ($password eq 'demo')) {

        $user = Gantry::Plugins::Uaf::User->new($username);
        $user->attribute('login_attempts', 0);
        $user->attribute('last_access', time());
        $user->attribute('salt', $salt);
        $self->{gantry}->session_store('uaf_remote_ip', $ip);
        $self->{gantry}->session_update('uaf_user', $user);

    }

    return $user;

}

sub invalidate($) {
    my $self = shift;

    $self->{gantry}->session_remove('uaf_user');
    $self->{gantry}->session_remove('uaf_token');
    $self->{gantry}->session_remove('uaf_remote_ip');
    $self->{gantry}->set_cookie(
        {
            name => '_token_id_',
            expires => '0',
            value => ''
        }
    );

}

sub login($$) {
    my ($self, $action) = @_;

    my $user;
    my $count;
    my $limit;
    my $params;
    my $failures;
    my $uaf_title;
    my $uaf_wrapper;
    my $uaf_template;
    my $login_rootp;
    my $denied_rootp;
    my $gobj = $self->{gantry};
    my $loc = $gobj->location;
    my $app_rootp = $gobj->app_rootp || "/";

    
    $loc =~ s!^/$!!;
    $action = lc($action);
    $login_rootp = $loc . '/login';
    $denied_rootp = $login_rootp . '/denied';

    if ($action eq 'denied') {

        $uaf_title = $gobj->fish_config('uaf_denied_title') || 'Login Denied';
        $uaf_wrapper = $gobj->fish_config('uaf_denied_wrapper') || 'default.tt';
        $uaf_template = $gobj->fish_config('uaf_denied_template') || 'uaf_denied.tt';

        $gobj->template_wrapper($uaf_wrapper);
        $gobj->stash->view->title($uaf_title);
        $gobj->stash->view->template($uaf_template);

    } else {

        if ($gobj->method eq 'POST') {

            $limit = $self->{limit};
            $params = $gobj->get_param_hash();
            $count = $gobj->session_retrieve('uaf_login_attempts');
            $count++;
            $gobj->session_update('uaf_login_attempts', $count);

            $user = $self->validate($params->{username}, 
                                    $params->{password});

            if (defined($user)) {

                $gobj->session_update('uaf_user', $user);

                if ($count > $limit) {

                    $self->relocate($denied_rootp);
                    return;

                }

                $gobj->session_update('uaf_login_attempts', 0);
                $self->set_token($user);
                $self->relocate($app_rootp);

            } else {

                $self->relocate($login_rootp); 

            }

        } else {

            $uaf_title = $gobj->fish_config('uaf_title') || 'Please Login';
            $uaf_wrapper = $gobj->fish_config('uaf_wrapper') || 'default.tt';
            $uaf_template = $gobj->fish_config('uaf_template') || 'uaf_login.tt';

            $gobj->template_wrapper($uaf_wrapper);
            $gobj->stash->view->title($uaf_title);
            $gobj->stash->view->template($uaf_template);

        }

    }

}

sub logout {
    my ($self) = shift;

    my $app_rootp = $self->{gantry}->app_rootp || "/";

    $self->invalidate();
    $self->relocate($app_rootp);

}

sub relocate($$) {
    my ($self, $url) = @_;

    $self->{gantry}->relocate($url);

}

sub set_token($$) {
    my ($self, $user) = @_;

    my $salt = $user->attribute('salt');
    my $path = $self->{gantry}->fish_config('uaf_cookie_path') || '/';
    my $domain = $self->{gantry}->fish_config('uaf_cookie_domain') || "";
    my $secure = $self->{gantry}->fish_config('uaf_cookie_secure');
    my $token = $self->{crypt}->encrypt($user->username, ':', time(), ':', $salt, $$);


    $self->{gantry}->set_cookie(
        {
            name => '_token_id_',
            value => $token,
            path => $path
        }
    );

    $self->{gantry}->session_update('uaf_token', $token);

}

sub avoid {
    my $self = shift;

    return 1;

}

sub filter($) {
    my ($self) = @_;

    return $self->{filter};

}

sub login_rootp($) {
    my ($self) = @_;

    return $self->{login_rootp};

}

sub expired_rootp($) {
    my ($self) = @_;

    return $self->{expired_rootp};

}

sub denied_rootp($) {
    my ($self) = @_;

    return $self->{denied_rootp};

}

sub app_rootp($) {
    my ($self) = @_;

    return $self->{app_rootp};

}

1;

__END__

=head1 NAME

Gantry::Plugins::Uaf::Authenticate - An Basic Authentication Framework

=head1 DESCRIPTION

This class is responsible for authenicating, managing the session store
and creating the User object. This module should be overridden and extended
as needed by your application.

This module understands the following config settings:

 uaf_cookie_path     - The path for the security token, defaults to "/"
 uaf_cookie_domain   - The cookie domain, not currently used
 uaf_cookie_secure   - Wither the cookie should only be used with SSL

 uaf_title           - title for the login page, defaults to 'Please Login"
 uaf_wrapper         - the wrapper for the login page, defaults to "default.tt"
 uaf_template        - the template for the login page, defaults to "login.tt"

 uaf_denied_title    - title for the denied page, defaults to "Login Denied"
 uaf_denied_wrapper  - the wrapper for the denied page, defaults to "default.tt"
 uaf_denied_template - the template for the denied page, defaults to "login_denied.tt"

=over 4

=item new

This initilizes the object, the Gantry object needs to be passed with this
call.

=item is_valid($) 

This method is used to authenticate the current session. The
default authentication behaviour is based on security tokens. A token is 
storeed within the session store and a token is retireved from a cookie. If 
the two match, the session is condsidered autheticate. When the session is 
authenticated an User object is returned.

=item validate($$) 

This method handles the validation of the current session. It accepts two 
parameters. They are a username and password. When the session is validated, 
an User object is created and returned. The default validate() method only 
knows about "admin" and "demo" users, with default passwords of "admin" and 
"demo". This method should be overridden to refelect your applications Users 
datastore and validation policy.

=item invalidate($)

This method will invalidate the current session. You may wish to override this
method. By default it removes the User object form the session store, removes 
the secuity token from the session store and removes the security cookie.

=item login($$)

This method handles the url "/login" and any actions on that url. By default
this method display a simple login page which contains a login form. That form 
is submitted back to the "/login" url, where the username and password are 
processed. This processing is done by the validate() method. If validation is 
succesful an User object is created. This object is then stored within the 
session store so is_valid() can access it when doing session 
authentication. Also an initial security token is created. 

This method also implements a simple three tries at login attempts. If after 
three tries, all attempts are redirected to "/login/denied", which displays 
a simple "denied" page. After a succesful login, a redirect is sent for "/".

=item logout($)

This method handles the url "/logout". It runs the invalidate() method and 
then redirects back to "/".

=item relocate($$)

Handles relocations, it currently just calls the Gantry relocate() 
function.

=item set_token($$)

This method creates the security token. It is passed the User object. The 
default action is to create a token using parts of the User object and
random data. This token is then stored in the session store and sent to the
browser as a cookie.

=item avoid($)

Some application may wish to implement an avoidence scheme for certain
situations. This is a hook to allow that to happen. The default action is
to do nothing.

=item filter($)

This method returns the url filter that is used by uaf_authenticate().

=back

=head1 SEE ALSO

 Gantry
 Gantry::Plugins::Uaf 
 Gantry::Plugins::Uaf::Rule
 Gantry::Plugins::Uaf::User
 Gantry::Plugins::Uaf::Authorize

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
