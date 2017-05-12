package Eixo::Queue::QueueRabbit;

use strict;
use Scalar::Util qw(weaken);

use Eixo::Base::Clase "Eixo::Queue";

use Eixo::Queue::JobCifrador;
use Eixo::Queue::RabbitDriver;


has(


    host=>undef,

    port=>undef,

    vhost=>undef,

    user=>undef,

    password=>undef,

    driver=>undef,

    secret=>undef,

    exchange=>undef,

    routing_key=>undef,
);

sub initialize{

    $_[0]->SUPER::initialize(@_[1..$#_]);

    $_[0]->driver(

        Eixo::Queue::RabbitDriver->new(

            host=>$_[0]->host,

            port=>$_[0]->port,

            vhost=>$_[0]->vhost,

            user=>$_[0]->user,

            password=>$_[0]->password
        )

    );
}

sub add :Sig(self, Eixo::Queue::Job){
    my ($self, $job, $routing_key, $opciones) = @_;

    my $message = $self->__crypJob($job);

    $routing_key = $routing_key || $self->routing_key;

    $self->driver->publicar(

        $self->__crypJob($job),

        $self->exchange,

        $routing_key,

        $opciones
    );
}

sub addAndWait :Sig(self, Eixo::Queue::Job, s, CODE){
    my (

        $self, 
        $job, 
        $routing_key_wait, 
        $callback,
        $timeout

    ) = @_;

    $self->add($job, undef, {

        mandatory=>1,

    });

    $self->wait(
        $routing_key_wait, 
        $callback, 
        ref($job),
        $timeout
    );
}

sub suscribe :Sig(self, CODE){
    my ($self, $callback, $job_class) = @_;

    $job_class = $job_class || "Eixo::Queue::Job";

    my $kself = $self;

    weaken($kself);

    $self->__suscribe(

        $self->routing_key,

        sub {
            my ($message, $next, $end) = @_;

            my $job = $kself->__decryptJob(

                $message->cuerpo, 

                $job_class

            );

            $message->recibido();

            if($callback->($job)){
                $next->();
            }
            else{
                $end->();
            }

        }

    );
}

sub wait :Sig(self, s, CODE, s){
    my ($self, $routing_key_wait, $callback, $job_class, $timeout) = @_;

    my $kself = $self;

    weaken($kself);

    $timeout && eval{

        local $SIG{ALRM} = sub {

            $kself->driver->terminar();    

            $callback->("TIMEOUT");

         #   alarm(0);
        };

        alarm($timeout);

    };

    $self->__suscribe(

        $routing_key_wait,

        sub {
            my ($message, $next, $end) = @_;

            my $job = $kself->__decryptJob(

                $message->cuerpo, 

                $job_class

            );

            $message->recibido;

            $callback->(undef, $job);
            
            $end->();

        }

    );
    
}

sub __suscribe :Sig(self, s, CODE){
    my ($self, $routing_key_wait, $callback) = @_;

    $self->driver->suscribirse(

        $self->exchange,

        $routing_key_wait,

        $callback
    );
}


sub __decryptJob{
    my ($self, $message, $job_class) = @_;
    
    $job_class->new->descifrar(
        
        $message,

        $self->secret

    );
}

sub __crypJob{
    my ($self, $job) = @_;

    $job->cifrar($self->secret);
}


1;
