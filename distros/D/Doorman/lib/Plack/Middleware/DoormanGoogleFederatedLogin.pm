package Plack::Middleware::DoormanGoogleFederatedLogin;
use 5.010;
use strict;
use parent 'Doorman::PlackMiddleware';

use Net::Google::FederatedLogin;
use Plack::Request;
use Data::Dumper;

sub call {
    my ($self, $env) = @_;
    $self->prepare_call($env);
    $env->{"doorman.@{[ $self->scope ]}.googlefederatedlogin"} = $self;
    my $request = Plack::Request->new($env);

    given([$request->method, $request->path]) {
        when(['POST', $self->sign_in_path]) {
            if (my $id = $request->param("google-federated-login")) {
                my $g = Net::Google::FederatedLogin->new(
                    claimed_id => $id,
                    return_to  => $self->verified_url,
                );
                return [302, ["Location" => $g->get_auth_url], [""]];
            }
        }

        when(['GET', $self->verified_path]) {
            my $g = Net::Google::FederatedLogin->new(
                cgi => $request,
                return_to => $self->verified_url,
            );

            if (my $id = $g->verify_auth) {
                $self->session_set("verified_google_federated_login", $id);
                $self->env_set("status", "verified");
            }
            else {
                $self->env_set("status", "not_verified");
            }
        }

        when(['GET', $self->sign_out_path]) {
            $self->session_remove("verified_google_federated_login");
        }
    }

    return $self->app->($env);
}

sub verified_url {
    $_[0]->scope_url . "/google_federated_login_verified"
}

sub verified_path {
    URI->new($_[0]->verified_url)->path;
}

sub verified_identity_url {
    $_[0]->session_get("verified_google_federated_login");
}

sub is_sign_in {
    defined $_[0]->verified_identity_url;
}

1;
