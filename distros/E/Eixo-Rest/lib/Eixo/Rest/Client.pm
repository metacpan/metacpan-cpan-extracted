package Eixo::Rest::Client;
use strict;

use Eixo::Base::Clase;

use URI;
use LWP::UserAgent;
use LWP::Protocol::https;
use JSON -convert_blessed_universally;
use Carp;
use Data::Dumper;

use Config;
use Eixo::Rest::RequestSync;



my $REQ_PARSER = qr/\:\:([a-z]+)([A-Z]\w+?)$/;

my $USER_AGENT_VERSION = 'EixoAgent/0.1';

has(

    ua=>undef,
    endpoint=>undef,
    format=>'json',
    error_callback => undef,
    current_method => undef,
);

sub initialize{
    my ($self, $endpoint, %opts) = @_;

    $self->endpoint($endpoint);

    die("API ENDPOINT NEEDED") unless($self->endpoint);

    $self->ua($USER_AGENT_VERSION, %opts);

    $self;
}

sub ua {
    my ($self, $ua_str, %opts) = @_;

    if($ua_str){
        my $ua = LWP::UserAgent->new(%opts);
        $ua->agent($ua_str);
        $self->{ua} = $ua;
    }

    return $self->{ua};
}



sub AUTOLOAD{
    my ($self, %args) = @_;

    my ($method, $entity) = our $AUTOLOAD =~ $REQ_PARSER;
    
    # store current method for tracing
    $self->current_method($method.$entity);

    $entity = lc($entity);

    unless(grep { $method eq $_ } qw(put get post delete patch)){
        confess(ref($self) . ': UNKNOW METHOD: ' . $method);
    }

    my ($id, $action);

    if(exists($args{id})){
        $id = $args{id};
        delete($args{id});
    }

    if(exists($args{action})){
        $action = $args{action};
        delete($args{action});
    }

    if($args{__job_id}){
        $args{'__client_send_method'} = '__sendAsync';
    }
    else{
        $args{'__client_send_method'} = '__send';
    }

    if(!$args{__format}){
        $args{__format} = $self->format;
    }

    # set error_callback unless already established
    unless(defined($args{PROCESS_DATA}->{onError})){
    
        $args{PROCESS_DATA}->{onError} = sub {
    
            $self->remote_error(@_);
    
        };
    }

    my $uri;

    if($uri = $args{uri}) {
        $uri = $self->build_predefined_uri($uri);
    }
    else{
        $uri = $self->build_uri($entity, $id, $action, $args{__implicit_format});
    }

    $self->$method($uri, %args);

}

sub DESTROY {}

sub head: Log {
	my ($self, $uri, %args) = @_;

	$uri->query_form($args{GET_DATA});

	my $req = HTTP::Request->new(GET => $uri);

    $self->set_headers($req, $args{HEADER_DATA} || {});

	my $send_method = $args{__client_send_method};

    $self->$send_method($req, %args);
}

sub get: Log {

    my ($self, $uri, %args) = @_;

    $uri->query_form($args{GET_DATA});

	my $req = HTTP::Request->new(GET => $uri);

    $self->set_headers($req, $args{HEADER_DATA} || {});

	my $send_method = $args{__client_send_method};

    $self->__encode_request_body($req,%args);

    $self->$send_method($req, %args);
}

sub post: Log {
    my ($self,$uri,%args) = @_;

    # Is possible to add query string args to post requests
    $uri->query_form($args{GET_DATA});

    my $req = HTTP::Request->new(POST => $uri);
    
    $self->set_headers($req, $args{HEADER_DATA} || {});

    my $send_method = $args{__client_send_method};

    $self->__encode_request_body($req,%args);

    $self->$send_method($req, %args);
}

sub delete: Log {

    my ($self, $uri, %args) = @_;

    $uri->query_form($args{GET_DATA});

    my $req = HTTP::Request->new(DELETE => $uri);

    $self->set_headers($req, $args{HEADER_DATA} || {});

    my $send_method = $args{__client_send_method};

    $self->__encode_request_body($req,%args);

    $self->$send_method($req, %args);
}

sub patch: Log {
    my ($self, $uri, %args) = @_;

    $uri->query_form($args{GET_DATA});

    my $req = HTTP::Request->new(PATCH => $uri);

    $self->set_headers($req, $args{HEADER_DATA} || {});

    my $send_method = $args{__client_send_method};

    $self->__encode_request_body($req,%args);

    $self->$send_method($req, %args);

}

sub put: Log {
    my ($self, $uri, %args) = @_;

    $uri->query_form($args{GET_DATA});

    my $req = HTTP::Request->new(PUT=> $uri);

    $self->set_headers($req, $args{HEADER_DATA} || {});

    my $send_method = $args{__client_send_method};

    $self->__encode_request_body($req,%args);

    $self->$send_method($req, %args);
}


sub __encode_request_body{
    my ($self,$req, %args) = @_;

    return unless($args{POST_DATA});

    my $content;
    my $content_type = $req->header('Content-Type') 
        || 'application/json';
        #|| 'application/x-www-form-urlencoded';

    if($content_type eq "application/json"){

        $content = JSON->new->allow_blessed(1)
                            ->convert_blessed(1)#->utf8
                            ->encode($args{POST_DATA} || {});
    }
    else{
        
        # application/x-www-form-urlencoded
        # raw stream
        while(my ($key, $value) = each (%{$args{POST_DATA} || {}})){
            $content .= "$key=$value&";
        }

    }

    $req->header("Content-Type", "$content_type; charset=utf-8");
    $req->add_content_utf8($content) if($content);

}


sub build_uri {
    my ($self, $entity, $id,$action, $implicit_format) = @_;

    my $uri = $self->{endpoint}.'/'.$entity;
    
    $uri .= '/'.$id if(defined($id));
    $uri .= '/'.$action if(defined($action));

    return URI->new($uri) if($implicit_format);

        ($self->current_method =~ /^get/)?

            URI->new($uri.'/'.$self->{format}) :

            URI->new($uri);
}

sub build_predefined_uri{
    my ($self, $uri) = @_;

    my $endpoint = $self->{endpoint};
    
    $endpoint .= "/" unless($endpoint =~ /\/$/);

    $uri =~ s/^\///;

    return URI->new($endpoint . $uri)
}


sub generate_query_str {
    my ($self, %args) = @_;

    join '&', map {"$_=$args{$_}"} keys(%args);
}


sub __send{
    my ($self, $req, %args) = @_;

    Eixo::Rest::RequestSync->new(

        callback=>$args{__callback},

        %{$args{PROCESS_DATA}},

        __format=>$args{__format}

    )->send(

        $self->ua(), 

        $req

    );

}

sub __sendAsync{
    my ($self, $req, %args) = @_;

    die("unsupported:  ERROR: This Perl not built to support threads\n") if (! $Config{'useithreads'});

    eval 'use Eixo::Rest::RequestAsync';

    Eixo::Rest::RequestAsync->new(

        job_id=>$args{__job_id},

        api=>$args{api},

        callback=>$args{__callback},

        %{$args{PROCESS_DATA}},

        __format=>$args{__format}

    )->send(

        $self->ua(), 

        $req

    );

}

sub remote_error {
    my ($self,$response) = @_;

    my $status = $response->code;
    my $extra = $response->content;

    if(defined($self->error_callback)){

        &{$self->error_callback}(

            $self->current_method,

            'ERROR_CODE',

            $status,

            $extra,
            #@extra_args
            
        );
    }
    else{
        die "Remote Api error: ($status). Details: $extra\n";
    }
}

sub set_headers{
    my ($self, $req, $headers) = @_;

    $req->header($_, $headers->{$_}) foreach(keys %$headers);
}

1;
