package Eixo::Queue::RabbitDriver;

use strict;
use Eixo::Base::Clase;

use Eixo::Queue::RabbitMessage;

use Net::AMQP::RabbitMQ;

has(

	host=>'localhost',

	port=>5672,

    vhost=>undef,

    user=>undef,

    password=>undef,

    __ch => undef,

	__mq=>undef,
);

sub DESTROY{
    $_[0]->terminar;
}

sub terminar{

    if($_[0]->{__mq}){

        $_[0]->__mq->channel_close(1) if($_[0]->{__ch});

        $_[0]->__mq->disconnect();
    }

    $_[0]->{__mq} = $_[0]->{__ch} = undef;
}

sub publicar :Sig(self, s, s, s){
    my ($self, $mensaje, $intercambio, $enrutado, $opciones, $props) = @_;

    $self->__abrirCanal;

    $self->__mq->exchange_declare(

        1,

        $intercambio,
        
        {
            durable=>1,
        }
    );

    my $opts;

    $self->__mq->publish(

        1,

        $enrutado,

        $mensaje,

        $opts = {

            exchange=> $intercambio,

            %{$opciones || {}}
        },

    );
}

sub suscribirse :Sig(self, s, s, CODE){
    my ($self, $intercambio, $enrutado, $callback) = @_;

    $self->__abrirCanal;

    $self->__mq->exchange_declare(

        1,

        $intercambio,

        {
            durable=>1,
        }
    );

    my $queue = $self->__mq->queue_declare(1, "");

    $self->__mq->queue_bind(1, $queue, $intercambio, $enrutado);

    $self->__mq->consume(1, $queue, {

        no_ack=>0

    });

    my $f;

    $f = sub {

        print "Esperando mensaje\n";

        my $rv = $self->__mq->recv();
 
        $callback->(

            Eixo::Queue::RabbitMessage->new(

                driver=>$self,

                message=>$rv
            ),

            sub { $f->() },

            sub { goto SALIR }
    
        );   
    };

    $f->();    

    return;

    SALIR:
    
        $self->terminar();
}

sub mensajeRecibido{ #:Sig(self, s){
    my ($self, $tag) = @_;

    $self->__mq->ack(1, $tag);
}

sub __abrirCanal{

    return if($_[0]->__ch);

    $_[0]->__abrirConexion;

    $_[0]->{__ch} = 1;

    $_[0]->__mq->channel_open(1);
        
}

sub __cerrarCanal{

    return unless($_[0]->__ch);

    $_[0]->__mq->channel_close(1);

    $_[0]->{__ch} = 0;
}

sub __abrirConexion{

    return if($_[0]->{__mq});

    $_[0]->{__mq} = Net::AMQP::RabbitMQ->new;

    $_[0]->{__mq}->connect(

        $_[0]->host,

        {
            port=>$_[0]->port,

            user=>$_[0]->user,

            password=>$_[0]->password,

            vhost=>$_[0]->vhost,

            timeout=>1
        }

    )
}



1;
