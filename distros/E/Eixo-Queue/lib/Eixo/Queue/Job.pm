package Eixo::Queue::Job;

use strict;
use Eixo::Base::Clase;

use JSON;
use Data::UUID;

use Eixo::Queue::JobCifrador;

my $UUID_INSTANCE;

BEGIN{
    $UUID_INSTANCE = Data::UUID->new;
}

sub WAITING     { 'WAITING' }
sub PROCESSING    { 'PROCESSING' }
sub FINISHED    { 'FINISHED' }
sub ERROR    { 'ERROR' }


sub ID{

    $UUID_INSTANCE->create_str;
}

my %NO_SERIALIZE = (
    #id => 1
);


has(

    id=> undef,

    queue=>undef,

    status=>WAITING,

    creation_timestamp=>time,

    start_timestamp => undef,
    
    termination_timestamp => undef,

    args=>undef,

    results=>undef,

);


sub initialize {
    my ($self,@args) = @_;

    $self->{id} = &ID;
    $self->{args} = {};
    $self->{results} = {};

    $self->SUPER::initialize(@args);
    
}

sub to_hash {

    return {

        map {
            $_ => $_[0]->{$_}
        }
        grep{
            !$NO_SERIALIZE{$_}
        }
        keys(%{ $_[0] })
    
    }
}

sub TO_JSON {
    $_[0]->to_hash
}

sub copy{
    my ($self, $j) = @_;

    $self->{$_} = $j->{$_} foreach(keys(%$j));
}

sub processing{
    
    $_[0]->start_timestamp(time) && $_[0]->status(PROCESSING)
}

sub finished{

    $_[0]->termination_timestamp(time) && $_[0]->status(FINISHED)

}


sub serialize{
    my ($self) = @_;

    JSON->new->convert_blessed->encode( $self )
}

sub unserialize{
    my ($package, $data) = @_;

    if(ref($package)){
        $package = ref($package);
    }

    bless(JSON->new->decode($data), $package);
}

sub setArg{
    my ($self, $key, $value) = @_;

    $self->args->{$key} = $value;
}

sub setResult{
    my ($self, $key, $value) = @_;

    $self->results->{$key} = $value;
}

sub removeResult{
    my ($self, $key) = @_;

    delete($self->results->{$key});
} 
sub cifrar :Sig(self, s){
    Eixo::Queue::JobCifrador->new->cifrar(@_);
}

sub descifrar :Sig(self, s, s){
    Eixo::Queue::JobCifrador->new->descifrar(@_);
}


1;
