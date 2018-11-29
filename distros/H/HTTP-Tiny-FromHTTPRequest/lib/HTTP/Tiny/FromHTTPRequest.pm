package HTTP::Tiny::FromHTTPRequest;

# ABSTRACT: Perform a request based on a plain HTTP request or HTTP::Request object

use strict;
use warnings;

use parent 'HTTP::Tiny';

use Carp;
use Scalar::Util qw(blessed);
use HTTP::Request;

our $VERSION = '0.02';

sub request {
    my ($self, @params) = @_;

    local $Carp::Internal{ 'HTTP::Tiny::FromHTTPRequest' } = 1;

    (@_ >= 2 )
        or Carp::croak(q/Usage: $http->request(METHOD, URL, [HASHREF])/ . "\n");

    my @methods = qw(get head put post delete);
    if ( !ref $params[0] &&  grep{ lc $params[0] eq $_ }@methods ) {
        return $self->SUPER::request( @params );
    }

    my $request;
    if ( blessed $params[0] and $params[0]->isa('HTTP::Request') ) {
        $request = $params[0];
    }
    elsif ( ! ref $params[0] ) {
        $request = HTTP::Request->parse( $params[0] );
    }

    Carp::croak(q/Usage: $http->request(METHOD, URL, [HASHREF])/ . "\n") if !$request;

    my %options;

    # add headers
    $options{headers} = { $request->headers->flatten };
    delete $options{headers}->{Host};

    my $content = $request->content;
    if ( $content ) {
        $options{content} = $content;
    }

    return $self->SUPER::request(
        $request->method,
        $request->uri,
        \%options,
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::FromHTTPRequest - Perform a request based on a plain HTTP request or HTTP::Request object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use v5.10;
    use HTTP::Tiny::FromHTTPRequest;
    use HTTP::Request;
  
    my $http = HTTP::Tiny::FromHTTPRequest->new;
  
    my $plain_request = q~
    POST / HTTP/1.1
    Content-Length: 104
    User-Agent: HTTP-Tiny/0.025
    Content-Type: multipart/form-data; boundary=go7DX
    Connection: close
    Host: localhost:3000
    
    --go7DX
    Content-Disposition: form-data; name="file"; filename="test.txt"
    
    This is a test
    --go7DX--
    ~;
    
    my $response_from_object = $http->request( HTTP::Request->parse( $plain_request ) );
    if ( $response_from_object->{success} ) {
        say "Successful request from HTTP::Request object";
    }
    
    my $response_from_plain  = $http->request( $plain_request );
    if ( $response_from_plain->{success} ) {
        say "Successful request from plain HTTP request";
    }

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
