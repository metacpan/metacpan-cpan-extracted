package Eixo::Queue::RabbitMessage;

use strict;
use Eixo::Base::Clase;

has(

    driver=>undef,

    message=>undef

);

sub cuerpo{

    $_[0]->message->{body};
}

sub recibido{
    my ($self) = @_;

    $self->driver->mensajeRecibido(

        $self->message->{delivery_tag}

    );
}

sub responder :Sig(self, s, s, s){
    my ($self, $mensaje, $enrutado, $intercambio) = @_;

    $self->driver->__mq->publish(

        1,

        $enrutado,

        $mensaje,

        {
            exchange => $intercambio

        }

    );
}

1;
