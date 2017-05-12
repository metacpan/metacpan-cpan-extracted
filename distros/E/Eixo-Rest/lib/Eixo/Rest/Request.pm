package Eixo::Rest::Request;

use strict;
use Eixo::Base::Clase;

use Attribute::Handlers;
use Carp;

has (
    callback=>undef,

    onProgress => undef,
    onSuccess =>  undef,
    onError => undef,
    onStart => undef,
    
    __format=>'json',

    buffer=>'',

);

sub start{
    my ($self) = @_;

    $self->{buffer} = ''; # truncate the buffer

    if($self->onStart){
        $self->onStart->();
    }
}

sub end{
    
    my ($self, $response) = @_;

    my $content = $self->unmarshall($response);
    
    &{$self->onSuccess}(
        
        $self->callback->($content, $self),

        $content

    );

}

sub error{
    my ($self, $response) = @_;

    &{$self->onError}($response);
    #     $response->code,
    #     $response->content,
    # );

}

sub progress{
    my ($self, $chunk, $req) = @_;

    $self->buffer($self->buffer . $chunk);

    $self->onProgress->($chunk, $req) if($self->onProgress);
}   

sub process {die ref($_[0]) . "::process: MUST BE DEFINED"}

sub send {die ref($_[0]) . "::send: MUST BE DEFINED"}

sub unmarshall{
    my ($self, $response) = @_;

    my $content = $response->decoded_content(
        default_charset=> 'UTF-8'
    );

    # nowadays (HTTP::Message v6.11)
    # decoded_content isn't decoding utf8 charset
    # if content_type is application/json
    if($response->content_type eq 'application/json'){
        use Encode;
        $content = Encode::decode('UTF-8', $content);
    }

    if($self->__format eq 'json'){

        return JSON->new->decode($content || '{}')
    }
    else{
        return $content;
    }
}



1;
