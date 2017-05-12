package Eixo::Rest::RequestSync;

use strict;
use Eixo::Base::Clase 'Eixo::Rest::Request';
use Data::Dumper;



sub send{
    my ($self, $ua, $req) = @_;

    #
    # DEBUG HANDLERS:
    #
    # $ua->add_handler(
    #     response_data => sub {
    #                     my($response, $ua, $h, $data) = @_; 
    #                     print "Recibimos chunk '$data' ca response $response"},
    #     verbose => 1
    # );

    # $ua->add_handler(
    #     response_done => sub {
    #         my($response, $ua, $h) = @_;
    #         print "Finalizou a request: response = ".Dumper($response);
    #     },
    #     verbose => 1
    # );


    $self->start();

    #print Dumper($req);

    my $res = ($self->onProgress)? 

        $ua->request($req, sub {

            $self->progress(@_);

        }) : $ua->request($req);
    
    #print Dumper($res);

    if($res->is_success){
        return $self->end($res);
    }
    else{
        return $self->error($res);
    }

    # $self;
}

1;
