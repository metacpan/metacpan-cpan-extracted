package t::SamlHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => {
    samlGotAuthnRequest      => 'gotRequest',
    samlGenerateAuthnRequest => 'genRequest',
    samlGotAuthnResponse     => 'gotResponse',
    samlBuildAuthnResponse   => 'genResponse',
};

sub genResponse {
    my ( $self, $req, $login ) = @_;
    use Test::More;
    $login->response->Assertion->AuthnStatement->AuthnInstant(
        "2000-01-01T00:00:01Z");
    return 0;
}

sub gotRequest {
    my ( $self, $req, $login ) = @_;

    $req->pdata->{gotRequestHookCalled} = 1;
    return 0;
}

sub genRequest {
    my ( $self, $req, $idp, $login ) = @_;

    $req->pdata->{genRequestHookCalled} = 1;
    return 0;
}

sub gotResponse {
    my ( $self, $req, $idp, $login ) = @_;

    $req->sessionInfo->{gotResponseHookCalled} = 1;
    $req->pdata->{gotResponseHookCalled}       = 1;
    return 0;
}

1;

