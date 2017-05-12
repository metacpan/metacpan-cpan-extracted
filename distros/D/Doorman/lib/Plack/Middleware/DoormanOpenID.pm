package Plack::Middleware::DoormanOpenID;
use 5.010;
use strict;

our $VERSION   = "0.06";
our $AUTHORITY = "http://gugod.org";

use feature qw(switch);
use parent 'Doorman::PlackMiddleware';

use Plack::Request;
use Plack::Util::Accessor qw(secret ua);

use Net::OpenID::Consumer;
use LWP::UserAgent;
use URI;
use Scalar::Util qw(weaken);

sub prepare_app {
    my $self = shift;

    $self->SUPER::prepare_app(@_);

    $self->secret(
        'This is the default consumer_secret value for Net::OpenID::Consumer
         that you should provide for your own app. ' . $VERSION
    ) unless $self->secret;
    $self->ua('LWP::UserAgent') unless $self->ua;
}

sub openid_verified_url {
    $_[0]->scope_url . "/openid_verified";
}

sub openid_verified_path {
    URI->new($_[0]->openid_verified_url)->path;
}

sub verified_identity_url {
    $_[0]->session_get("verified_identity_url");
}

sub is_sign_in {
    defined $_[0]->verified_identity_url;
}

sub csr {
    my ($self, $request) = @_;
    return Net::OpenID::Consumer->new(
        ua => ref($self->ua) ? $self->ua : $self->ua->new,
        args => sub { $request->param($_[0]) },
        consumer_secret => $self->secret,
        required_root   => $self->root_url
    );
}

sub call {
    my ($self, $env) = @_;
    $self->prepare_call($env);

    $env->{"doorman.@{[ $self->scope ]}.openid"} = $self;

    my $request = Plack::Request->new($env);
    given([$request->method, $request->path]) {
        when(['POST', $self->sign_in_path]) {
            my $csr = $self->csr($request);
            if ($request->param("openid")) {
                if (my $claimed_identity = $csr->claimed_identity( $request->param("openid") )) {
                    my $check_url = $claimed_identity->check_url(
                        delayed_return => 1,
                        return_to      => $self->openid_verified_url,
                        trust_root     => $self->root_url
                    );

                    return [302, ["Location" => $check_url], [""]];
                }
                else {
                    $env->{'doorman.'. $self->scope .'.openid.status'} = 'error';
                    $env->{'doorman.'. $self->scope .'.openid.error'} = $csr->errcode;
                }
            }
        }

        when(['GET', $self->openid_verified_path]) {
            my $csr = $self->csr($request);

            $csr->handle_server_response(
                verified => sub {
                    my $id = shift;

                    $env->{'doorman.'. $self->scope .'.openid.verified_identity'} = $id;
                    $env->{'doorman.'. $self->scope .'.openid.status'} = 'verified';

                    $self->session_set("verified_identity_url", $id->url);
                },
                setup_required => sub {
                    $self->env_set("status", "setup_required");
                },
                cancelled      => sub {
                    $self->env_set("status", "cancelled");
                },
                not_openid     => sub {
                    $self->env_set("status", "not_openid");
                },
                error          => sub {
                    my $err = shift;
                    $self->env_set("status", "error");
                    $self->env_set("error",  $err);
                }
            );
        }

        when(['GET', $self->sign_out_path]) {
            $self->session_remove("verified_identity_url");
        }
    }

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::DoormanOpenID - The OpenID sign-in middleware.

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
        enable "Session::Cookie";
        enable "DoormanOpenID", scope => 'users';

        sub {
            my $env = shift;
            my $doorman = $env->{'doorman.users.openid'};

        }
    };

=head1 DESCRIPTION

=head1 OPTIONS

=over 4

=item * secret

YOU MUST PROVIDE THIS VALUE IN YOUR PRODUCTION APP.

The consumer secret string to initiate the Net::OpenID::Consumer object. It should be a long, random,
difficult-to-guess string. For example:

    T{"<gshFg$Xi<]|r%io\%7MS]'Foj=)2YKiGeB<6FFePPS*h}%meU?H]0/Pu,x/QX.Vq4\Pljr=)yjcI]/M(EFft~_)'$wsIEZuCbc=uWpj-5Fkp>GZl~|/_-4Qk`+4F&V8cg%{/a\-<

DoormanOpenID provides some default value for you to quickly play with
Doorman without having to provide too many configs. However, if you do
not provide your own value, malicious attackers might be able forge
your app in a man-in-middle attacking scenario.

=item * scope

This setting is optional with default value "users", and useful if you
need multiple roles to login in to your system.

For example, if you need "users" and "admins" roles to have different login session,
you can achieve it by:

    enable "DoormanOpenID", scope => "users";
    enable "DoormanOpenID", scope => "admins";

For each scope, a path named after that scope is taken by DoormanOpenID middleware
as the end-points to perforam openid login.

By default, the following paths and HTTP methods are responded by the
DoormanOpenID middleware:

    POST /users/sign_in
    GET  /users/sign_out
    GET  /users/openid_verified

For the "admins" scope, it'll add:

    POST /admins/sign_in
    GET  /admins/sign_out
    GET  /admins/openid_verified

=item * root_url

The application root url that consumes openid. Usually this is guessed, and good enough.
If your application lives under some path, like, http://foo.com/app, you need to pass that
as the value of this.

=head1 METHODS

=over 4

=item * is_sign_in

Returns true if the current session is considered signed in.

=item * verified_identity_url

Returns the verified OpenID URL if current session is sign in. Returns undef otherwise.

=item * sign_in_path, sign_in_url

Returns a path, or full url, that is used to let user POST an openid
url to sign in. It should be used as the value of "action" attribute
of a form. For example:

    my $doorman = $env->{'doorman.users.openid'};

    my $sign_in_form = <<HTML;
    <form method="POST" action="@{[ $doorman->sign_in_path ]}">
        <label for="openid">OpenID</label>
        <input type="text" id="openid" name="openid" autofocus>
        <input type="submit" value="Sign In">
    </form>
    HTML

At this point you need to name the parameter C<openid>.

=item * sign_out_path, sign_out_url

Returns a path that, when visited, wipes out the signed in information in the session.

=back
