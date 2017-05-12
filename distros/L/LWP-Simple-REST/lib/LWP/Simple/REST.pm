package LWP::Simple::REST;

use strict;
use warnings FATAL => 'all';

use Cwd;

use Exporter qw( import );
our @EXPORT_OK = qw/
    HEAD
    GET
    POST
    DELETE
    PUT
    json
    plain
    headers
    response
    http_get
    http_post
    http_put
    http_delete
    http_head
    http_upload
    json_get
    json_post
    json_put
    json_head
/;

use LWP::UserAgent;
use HTTP::Request;
use Try::Tiny;
use JSON;

our $VERSION = '0.20';

my $user_agent = "LWP::Simple::REST";
my $lwp = LWP::UserAgent->new;
my $response;

sub user_agent { $lwp->agent( $_[0] ) }

sub response { $response }

sub plain { return ($_[0]->content ) }

sub json { return decode_json($_[0]->content ) }

sub headers { return $_[0] ? $_[0]->headers : $response->headers  };

sub POST {
    my ( $url, $arguments, $content ) = @_;

    $response = $lwp->post( $url, $arguments );
}

sub PUT {
    my ( $url, $arguments ) = @_;

    $response = $lwp->put( $url, $arguments );
}

sub GET {
    my ( $url, $arguments ) = @_;

    $arguments = _parameters( $arguments );

    $response = $lwp->get( $url, $arguments );
}

sub DELETE {
    my ( $url, $arguments ) = @_;

    $arguments = _parameters( $arguments );

    $response = $lwp->delete( $url, $arguments );
}

sub HEAD {
    my ( $url, $arguments ) = @_;

    $arguments = _parameters( $arguments );

    $response = $lwp->head( $url, $arguments );
}

sub _parameters {
    my ( $arguments ) = @_;
    my @parameters;
    while( my ( $key, $value )  = each %{ $arguments } ) {
        push @parameters, "$key=$value";
    }
    return '?' . ( join '&', @parameters );
}

sub upload_post {
    my ( $url, $json, $filename ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent('RESTClient');

    my $response = $ua->post(
        $url,
        [
            file => [ $filename ],
        ],
        'Content_Type' => 'form-data',
    );

    return answer( $response );
}

#
# The functions above are kept for the sake of compatibility
#

sub http_get { plain &GET }

sub http_post { plain &POST }

sub http_put { plain &PUT }

sub http_delete { plain &DELETE }

sub http_head { headers &HEAD }

sub json_post { json &POST }

sub json_put { json &PUT }

sub json_get { json &GET }

sub answer {
    my ( $response ) = @_;

    my $http_code = $response->code();
    my $return = $response->decoded_content;

    if ( $response->is_success ){
        my $answer;
        if ( $http_code =~ /(2\d\d)/ ){
            if ( $1 == 204 ){
                return $return;
            }else{
                return decode_json( $return );
            }
        }
    }
    my $status = $response->status_line;
}

=head1 NAME

LWP::Simple::REST - A simple funcional interface to LWP::UserAgent, focused to 
                    quick use and test HTTP/REST apis

=head1 VERSION

Version 0.2

=head1 SYNOPSIS

This module is a simple wrapper for simple http requests. It provides functions
to create clients to whatever http services, mainly REST ones. The goal is to be 
simple and straight forward.

This version 0.2 tries to make it simpler, instead of have dozens of methods we just
have the basic method and let you combine them as you need. The old ones are kept for
compatibilty but are now deprecated.

This is the actual main example:

    use LWP::Simple::REST qw/POST json plain/;

    my $foo = plain POST ( "http://example.org", { example => "1", show => "all" } );
    
    or decoding the interface

    my $foo = json POST ( "http://example.org", { example => "1", show => "all" } );

In fact, the old http_post routine is actually just a wrapper for plain POST

The http verbs are all caps, and normal methods are in low case. You need to ask 
to export them.

=head1 SUBROUTINES/METHODS

All http verbs methods receive an url and a hashref with parameters. The other methods 
have each one it own interface.

=head2 GET, PUT, POST, DELETE, HEAD

They are the http verbs, they return an HTTP::Response object

=head2 plain

Receives an response and returns just the content, usually the calls will be like

my $var = plain POST ( $url, $arguments )

=head2 json

Same for above, but also decode_json the content

=head2 Old deprecated methods:

http_get, http_post, http_delete http_head http_upload json_get json_post

Are old methods kept just for compatibility, actually it will be preferred to
use the new interface:

headers HEAD $url, $parameters

=head1 AUTHOR

RECSKY, C<< <recsky at cpan.org> >>
GONCALES, C<< <italo.goncales at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lwp-simple-rest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Simple-REST>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::Simple::REST

Usually we are on irc on irc.perl.org.

    #sao-paulo.pm

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-Simple-REST>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-Simple-REST>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-Simple-REST>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 GONCALES
Copyright 2014 RECSKY

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of LWP::Simple::REST
