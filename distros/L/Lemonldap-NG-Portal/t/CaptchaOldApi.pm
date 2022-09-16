package t::CaptchaOldApi;

use Mouse;
use Lemonldap::NG::Portal::Main::Constants;
extends 'Lemonldap::NG::Portal::Main::Plugin';

has 'captcha' => ( is => 'rw' );

sub init {
    my $self = shift;

    $self->addUnauthRoute( validateCaptcha => 'validateCaptcha', ['POST'] );
    $self->addUnauthRoute( setCaptcha      => 'setCaptcha',      ['POST'] );
    $self->addUnauthRoute( getCaptcha      => 'getCaptcha',      ['POST'] );
    $self->captcha( $self->p->loadModule('::Lib::Captcha') );
    return 1;
}

sub setCaptcha {
    my ( $self, $req ) = @_;

    $self->captcha->setCaptcha($req);

    my $info = $self->captcha->ott->getToken( $req->token, 1 );

    return $self->sendJSONresponse(
        $req,
        {
            token  => $req->token,
            img    => $req->captcha,
            answer => $info->{captcha}
        }
    );
}

sub getCaptcha {
    my ( $self, $req ) = @_;

    my ( $token, $image ) = $self->captcha->getCaptcha;
    my $info = $self->captcha->ott->getToken( $token, 1 );

    return $self->sendJSONresponse( $req,
        { token => $token, img => $image, answer => $info->{captcha} } );
}

sub validateCaptcha {
    my ( $self, $req ) = @_;
    my $token  = $req->param('token');
    my $answer = $req->param('answer');

    my $result = $self->captcha->validateCaptcha( $token, $answer );

    return $self->sendJSONresponse( $req, { result => $result } );

}

1;
