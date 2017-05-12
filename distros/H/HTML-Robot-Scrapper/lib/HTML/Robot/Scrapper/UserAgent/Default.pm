package  HTML::Robot::Scrapper::UserAgent::Default;
use Moose;
use Data::Printer;
use HTTP::Tiny;
use HTTP::Headers::Util qw(split_header_words);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
#use utf8;

has robot => ( is => 'rw', );
has engine => ( is => 'rw', );

=head1 DESCRIPTION

This is the user agent class. It is responsible to handle the page visit, 

 and page content/parsing calls.

=cut

has [ qw/
             headers
     request_headers 
    response_headers
             content
             content_type
             charset
             url
/ ] => ( is => 'rw' );

=head2 ua

The default ua is HTTP::Tiny. However, it is possible to create a new class

just like this one and make it work with other user agents.

=cut

has ua => ( is => 'rw', default => sub { HTTP::Tiny->new() } );

sub _headers {
    my ( $self, $headers ) = @_;
    $self->headers( $headers ) if defined $headers;
    return $self->headers;
}

sub _request_headers {
    my ( $self, $headers ) = @_;
    $self->request_headers( $headers ) if defined $headers;
    return $self->request_headers;
}

sub _response_headers {
    my ( $self, $headers ) = @_;
    $self->response_headers( $headers ) if defined $headers;
    return $self->response_headers;
}

sub _content {
    my ( $self, $content ) = @_;
    $self->content( $content ) if defined $content;
    return $self->content;
}

sub _content_type {
    my ( $self, $content_type ) = @_;
    $self->content_type( $content_type ) if defined $content_type;
    return $self->content_type;
}

sub _charset {
    my ( $self, $charset ) = @_;
    $self->charset( $charset ) if defined $charset;
    return $self->charset;
}

sub _url {
    my ( $self, $url ) = @_;
    $self->url( $url ) if defined $url;
    return $self->url;
}

#visit the url and load into xpath and redirects to the method

=head2 visit

    Will visit the url you appended/prepended to the queue
    
    ex.

    $self->robot->queue->append( search => 'http://www.url.com', {
        passed_key_values => {
            send   => 'var across requests',
            some   => 'vars i collected here...... and ....',
            i_will => 'pass them to the next page because ...',
            i_need => 'stuff from this page and the other ',
        },
        request => [ <---- OPTIONAL... force custom request
            'GET',
            'http://www.lopes.com.br/imoveis/busca/-/'.$estado.'/-/-/-/aluguel-de-0-a-10000/de-0-ate-1000-m2/-/60',
            {
                headers => {
                    'Content-Type' => 'application/x-www-form-urlencoded',
                },
                content => '',
            }
        ]
    } );
    
=cut

sub visit {
    my ( $self, $item ) = @_;
    if ( defined $self->robot->cache ) {
        my $sha1 = Digest::SHA1->new;
        $self->url( $item->{ url } );
        $sha1->add( $item->{ url } );
        $self->robot->queue->add_visited( $item->{ url } );
        my $sha1_key    = $sha1->hexdigest;
        my $res         = $self->robot->cache->get( $sha1_key );
        if ( ! $res ) {
            $res = $self->_visit( $item );
            $self->robot->cache->set( $sha1_key, $res );
            $self->parse_response( $res ); #todo: passar parametros melhor. ex: 10minutos pro cache..
            return $res;
        } else {
            $self->parse_response( $res );
            return $res;
        }
    } else {
        $self->url( $item->{ url } ) if ( exists $item->{ url } );
        my $res = $self->_visit( $item );
        $self->parse_response( $res );
        return $res;
    }
}

sub _visit {
    my ( $self, $item ) = @_; 
    my $res = undef;
    if ( exists $item->{ request } and
            ref $item->{ request } eq ref [] )
    {
        $res = $self->ua->request( @{ $item->{ request } } );
        $self->url( $item->{ request }[1] );
    }
    else
    {
        $res = $self->ua->get( $item->{ url } );
        $self->url( $item->{ url } );
    }
    $self->parse_response( $res );
    return $res;
}


sub parse_response {
    my ( $self, $res ) = @_; 
    my $headers = $res->{ headers };
    $self->content( $res->{ content } );
    $self->parse_content( $res );
}

=head2 parse_content

Here the useragent will loop over defined content types and 

will call the proper subroutine to treat page->content based

on content type.

=cut

sub parse_content {
    my ( $self, $res ) = @_;
    my $content_types_avail = $self->robot->parser->content_types;
    #set headers
    $self->headers( $res->{ headers } );
    $self->response_headers( $res->{ headers } );
    #content type
    my $content_type =$res->{headers}->{'content-type'};
    $self->content_type( $content_type );
    #charset
    my $content_charset = $self->charset_from_headers( $res->{ headers } );
    $self->charset( $content_charset );

    my $content_type_found = 0;
    foreach my $ct (keys %$content_types_avail ) {
        foreach my $parser ( @{ $content_types_avail->{$ct} } ) {
            next unless $content_type =~ m/^$ct/ig;
            my $parse_method = $parser->{parse_method};
#           my $content = $res->{content};
            $self->robot->parser->$parse_method( $self->content );
            $content_type_found = 1;
        }
    }
    print "**** Content type not set for: " . $content_type . '... please configure it correctly adding a parser for that content type'."\n" if !$content_type_found;
#   foreach my $ct ( keys $self->parser_content_type ) {
#       if ( $self->response->{ headers }->{'content-type'} =~ m|^$ct|g ) {
#           my $parser_method = $self->parser_methods->{ $self->parser_content_type->{ $ct } };
#           $self->$parser_method();
#       }
#   }
#   my $reader_method = $item->{method};
#   $self->$reader_method;    #redirects back to method
}

sub charset_from_headers {
    my ( $self, $headers ) = @_;
    my $ct = $headers->{'content-type'};
    my $charset ;
    if ( $ct =~ m/charset=([^;|^ ]+)/ig ) {
        $charset = $1;
    }
    return $charset;
}

sub normalize_url {
    my ( $self, $url ) = @_;
#   if (       ref $self->before_normalize_url eq ref {}
#       and exists $self->before_normalize_url->{is_active}
#              and $self->before_normalize_url->{is_active} == 1
#       and exists $self->before_normalize_url->{code}
#       ) {
#       $url = $self->before_normalize_url->{code}->( $url );
#   }
    if ( defined $url ) {
        $self->url( $url ) if ! defined $self->url;
        my     $final_url = URI->new_abs( $url , $self->url );
        return $final_url->as_string();
    }
}

before 'visit' => sub {
    my ( $self ) = @_; 
    $self->robot->benchmark->method_start('visit');
};

after 'visit' => sub {
    my ( $self ) = @_; 
    $self->robot->benchmark->method_finish('visit');
};

1;
