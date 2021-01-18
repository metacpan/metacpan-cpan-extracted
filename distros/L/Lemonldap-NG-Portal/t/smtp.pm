package main;

my $mail;
my $mail_envelope;

sub mail {
    return $mail;
}

sub envelope {
    return $mail_envelope;
}

package Email::Sender::Transport::LLNG::Test;

use Mouse;
use Lemonldap::NG::Portal::Lib::SMTP;
$Lemonldap::NG::Portal::Lib::SMTP::transport = __PACKAGE__->new();

extends 'Email::Sender::Transport';

sub send_email {
    my ( $self, $email, $envelope ) = @_;
    $mail          = $email->get_body;
    $mail_envelope = $envelope;
    return $self->success;
}

1;
