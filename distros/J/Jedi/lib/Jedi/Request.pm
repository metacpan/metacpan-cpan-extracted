#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Request;

# ABSTRACT: Request object

use strict;
use warnings;
our $VERSION = '1.008';    # VERSION

# USE
use HTTP::Body;
use CGI::Deurl::XS 'parse_query_string';
use CGI::Cookie::XS;
use Net::IP::XS;

# MOO PACKAGE
use Moo;

has 'env' => ( is => 'ro', required => 1 );

has 'path' => ( is => 'ro', required => 1 );

has 'params' => ( is => 'lazy' );

sub _build_params {
    my ($self) = @_;
    my $method = $self->env->{REQUEST_METHOD};
    if ( $method eq 'POST' || $method eq 'PUT' ) {
        return $self->_body->param;
    }
    else {
        return parse_query_string( $self->env->{QUERY_STRING} ) // {};
    }
}

has 'uploads' => ( is => 'lazy' );

sub _build_uploads {
    my ($self) = @_;
    my $method = $self->env->{REQUEST_METHOD};
    if ( $method eq 'POST' || $method eq 'PUT' ) {
        return $self->_body->upload;
    }
    else {
        return {};
    }
}

has 'cookies' => ( is => 'lazy' );

sub _build_cookies {
    my ($self) = @_;
    return CGI::Cookie::XS->parse( $self->env->{HTTP_COOKIE} // '' );
}

has 'scheme' => ( is => 'lazy' );

sub _build_scheme {
    my ($self) = @_;
    my $env = $self->env;

    return
           $env->{'X_FORWARDED_PROTOCOL'}
        || $env->{'HTTP_X_FORWARDED_PROTOCOL'}
        || $env->{'HTTP_X_FORWARDED_PROTO'}
        || $env->{'HTTP_FORWARDED_PROTO'}
        || $env->{'psgi.url_scheme'}
        || $env->{'PSGI.URL_SCHEME'}
        || '';
}

has 'base_host' => ( is => 'lazy' );

sub _build_base_host {
    my ($self) = @_;
    my $env = $self->env;

    return
           $env->{'HTTP_X_FORWARDED_HOST'}
        || $env->{'X_FORWARDED_HOST'}
        || $env->{'HTTP_HOST'}
        || '';
}

has 'port' => ( is => 'lazy' );

sub _build_port {
    my ($self) = @_;
    my ( $host, $port ) = split( /:/, $self->base_host );
    return $port if defined $port;
    return 80    if $self->scheme eq 'http';
    return 443   if $self->scheme eq 'https';
    return '';
}

has 'host' => ( is => 'lazy' );

sub _build_host {
    my ($self) = @_;
    my ( $host, $port ) = split( /:/, $self->base_host );
    return $host;
}

has 'real_ip' => ( is => 'lazy' );

sub _build_real_ip {
    my ($self) = @_;

    my $env = $self->env;
    my @possible_forwarded_ips
        = grep {
        $_->iptype
            !~ /^(?:LOOPBACK|LINK\-LOCAL|PRIVATE|UNIQUE\-LOCAL\-UNICAST|LINK\-LOCAL\-UNICAST|RESERVED)$/xo
        }
        grep {defined}
        map  { Net::IP::XS->new($_) }
        grep {defined} (
        $env->{'HTTP_CLIENT_IP'},
        split( /,\s*/xo, $env->{'HTTP_X_FORWARDED_FOR'} // '' ),
        $env->{'HTTP_X_FORWARDED'},
        $env->{'HTTP_X_CLUSTER_CLIENT_IP'},
        $env->{'HTTP_FORWARDED_FOR'},
        $env->{'HTTP_FORWARDED'},
        );

    return $possible_forwarded_ips[0]
        // Net::IP::XS->new( $env->{'REMOTE_ADDR'} // '' );
}

has 'remote_address' => ( is => 'lazy' );

sub _build_remote_address {
    my ($self) = @_;
    my $real_ip = $self->real_ip
        or return 0;
    return $real_ip->intip()->bstr();
}

has 'remote_address_str' => ( is => 'lazy' );

sub _build_remote_address_str {
    my ($self) = @_;
    my $real_ip = $self->real_ip
        or return '';
    return $real_ip->ip();
}

has 'base_url' => ( is => 'lazy' );

sub _build_base_url {
    my ($self) = @_;
    return $self->scheme . '://' . $self->base_host;
}
has 'url' => ( is => 'lazy' );

sub _build_url {
    my ($self) = @_;
    return $self->base_url . ( $self->env->{PATH_INFO} // '/' );
}

# PRIVATE

has '_body' => ( is => 'lazy' );

sub _build__body {
    my ($self) = @_;

    my $type   = $self->env->{'CONTENT_TYPE'}   || '';
    my $length = $self->env->{'CONTENT_LENGTH'} || 0;
    my $io     = $self->env->{'psgi.input'};
    my $body = HTTP::Body->new( $type, $length );
    $body->cleanup(1);

    while ($length) {
        $io->read( my $buffer, ( $length < 8192 ) ? $length : 8192 );
        $length -= length($buffer);
        $body->add($buffer);
    }

    return $body;
}

1;

__END__
=pod

=head1 NAME

Jedi::Request - Request object

=head1 VERSION

version 1.008

=head1 DESCRIPTION

This object is pass through the route, as a second params. (self, request, response).

You can get data from it, to generate your response

=head1 ATTRIBUTES

=head2 env

The environment variable, as it received from PSGI. This is a HASH.

=head2 path

The end of the path_info, without the road.

Ex:
	road("/test"), route("/me") # so /test/me/ will give the path /me/

The $ENV{PATH_INFO} is untouch, you can use that method to get the relative PATH.

The path always end with '/'.

=head2 params

If method is POST or PUT, it will parse the body, and extract the params.

Otherwise it parse the QUERY_STRING.

It always return an HASH, with:

	key => Scalar // [ARRAY of Values]

Ex:

	a=1&a=2&a=3&b=4&b=5&b=6&c=1

You receive:

  {	
   a => [1,2,3],
   b => [4,5,6],
   c => 1
  }

=head2 uploads

Return the file uploads.

For a request like test@test.txt, the form is : 

   	test => {
	    filename   "test.txt",
        headers    {
            Content-Disposition   "form-data; name="test"; filename="test.txt"",
            Content-Type          "text/plain"
        },
        name       "test",
        size       13,
        tempname   "/var/folders/_1/097rrrdd2s5dwqgd7hp6nlx00000gn/T/X4me5HO7L_.txt"
   	}

Ex with curl :

	curl -F 'test@test.txt' http://localhost:5000/post

You can read the tempname file to get the content. When the request is sent back, the file is automatically removed.

See <HTTP::Body> for more details.

=head2 cookies

Parse the HTTP_COOKIE, and return an HASH of ARRAY

Ex:

	a=1&b&c; b=4&5&6; c=1

You receive:

 {
  a => [1,2,3],
	b => [4,5,6],
	c => [1]
 }

=head2 real_ip

Return a Net::IP::XS representation of the most probable real ip

=head2 remote_address

Return the int version of the real_ip

=head2 remote_address_str

Return the str version of the real_ip

=head2 base_url

Return the path path of the URL, without the params

=head2 url

Return the full path of the URL, without the params

=head1 METHODS

=head2 scheme

Return the scheme from proxied proto or main proto

=head2 base_host

Return the host:port proxied or real

=head2 port

Return the port part of the base_host

If no port found, it will return the default port based on scheme

=head2 host

Return the host part of the base_host

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

