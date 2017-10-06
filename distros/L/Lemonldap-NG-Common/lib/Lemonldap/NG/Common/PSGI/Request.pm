package Lemonldap::NG::Common::PSGI::Request;

use strict;
use Mouse;
use JSON;
use URI::Escape;

our $VERSION = '1.9.13';

#       http          ://  server   / path      ? query      # fragment
# m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

has HTTP_ACCEPT          => ( is => 'ro', reader => 'accept' );
has HTTP_ACCEPT_ENCODING => ( is => 'ro', reader => 'encodings' );
has HTTP_ACCEPT_LANGUAGE => ( is => 'ro', reader => 'languages' );
has HTTP_AUTHORIZATION   => ( is => 'ro', reader => 'authorization' );
has HTTP_COOKIE          => ( is => 'ro', reader => 'cookies' );
has HTTP_HOST            => ( is => 'ro', reader => 'hostname' );
has REMOTE_ADDR => ( is => 'ro', isa => 'Str', reader => 'remote_ip' );
has REMOTE_PORT    => ( is => 'ro', isa => 'Int', reader => 'port' );
has REQUEST_METHOD => ( is => 'ro', isa => 'Str', reader => 'method' );
has SCRIPT_NAME    => ( is => 'ro', isa => 'Str', reader => 'scriptname' );
has SERVER_PORT    => ( is => 'ro', isa => 'Int', reader => 'get_server_port' );
has X_ORIGINAL_URI => ( is => 'ro', isa => 'Str' );
has PATH_INFO => (
    is      => 'ro',
    reader  => 'path',
    lazy    => 1,
    default => '',
    trigger => sub {
        my $tmp = $_[0]->{SCRIPT_NAME};
        $_[0]->{PATH_INFO} =~ s|//+|/|g;
        $_[0]->{PATH_INFO} =~ s|^$tmp|/|;
    },
);
has REQUEST_URI => (
    is      => 'ro',
    reader  => 'uri',
    lazy    => 1,
    default => '/',
    trigger => sub {
        my $uri = $_[0]->{X_ORIGINAL_URI} || $_[0]->{REQUEST_URI};
        $_[0]->{unparsed_uri} = $uri;
        $_[0]->{REQUEST_URI}  = uri_unescape($uri);
        $_[0]->{REQUEST_URI} =~ s|//+|/|g;
    },
);
has unparsed_uri => ( is => 'rw', isa => 'Str' );

has 'psgi.errors' => ( is => 'rw', reader => 'stderr' );

# Authentication

has REMOTE_USER => (
    is      => 'ro',
    reader  => 'user',
    trigger => sub {
        $_[0]->{userData} = { $Lemonldap::NG::Handler::Main::tsv->{whatTotrace}
              || _whatToTrace => $_[0]->{REMOTE_USER}, };
    },
);
has userData => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

# Query parameters
has _params => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has QUERY_STRING => (
    is      => 'ro',
    reader  => 'query',
    trigger => sub {
        my $self = shift;
        $self->{QUERY_STRING} = uri_unescape( $self->{QUERY_STRING} );
        my @tmp =
          $self->{QUERY_STRING}
          ? split /&/, $self->{QUERY_STRING}
          : ();
        foreach my $s (@tmp) {
            if   ( $s =~ /^(.+?)=(.+)$/ ) { $self->{_params}->{$1} = $2; }
            else                          { $self->{_params}->{$s} = 1; }
        }
    },
);

sub params {
    my ( $self, $key, $value ) = @_;
    return $self->_params unless ($key);
    $self->_params->{$key} = $value if ( defined $value );
    return $self->_params->{$key};
}

# POST management
#
# When CONTENT_LENGTH is set, store body in memory in `body` key
has 'psgix.input.buffered' => ( is => 'ro', reader => '_psgixBuffered', );
has 'psgi.input'           => ( is => 'ro', reader => '_psgiInput', );
has body                   => ( is => 'rw', isa    => 'Str', default => '' );
has CONTENT_TYPE => ( is => 'ro', isa => 'Str', reader => 'contentType', );
has CONTENT_LENGTH => (
    is      => 'ro',
    reader  => 'contentLength',
    lazy    => 1,
    default => 0,
    trigger => sub {
        my $self = shift;
        if ( $self->method eq 'GET' ) { $self->{body} = undef; }
        elsif ( $self->method =~ /^(?:POST|PUT)$/ ) {
            $self->{body} = '';
            if ( $self->_psgixBuffered ) {
                my $length = $self->{CONTENT_LENGTH};
                while ( $length > 0 ) {
                    my $buffer;
                    $self->_psgiInput->read( $buffer,
                        ( $length < 8192 ) ? $length : 8192 );
                    $length -= length($buffer);
                    $self->{body} .= $buffer;
                }
            }
            else {
                $self->_psgiInput->read( $self->{body},
                    $self->{CONTENT_LENGTH}, 0 );
            }
            utf8::upgrade( $self->{body} );
        }
    }
);
has error => ( is => 'rw', isa => 'Str', default => '' );

has respHeaders => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

# JSON parser
sub jsonBodyToObj {
    my $self = shift;
    unless ( $self->contentType =~ /application\/json/ ) {
        $self->error('Data is not JSON');
        return undef;
    }
    unless ( $self->body ) {
        $self->error('No data');
        return undef;
    }
    return $self->body if ( ref( $self->body ) );
    my $j = eval { from_json( $self->body, { allow_nonref => 1 } ) };
    if ($@) {
        $self->error("$@$!");
        return undef;
    }
    return $self->{body} = $j;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::PSGI::Request - HTTP request object for Lemonldap::NG
PSGIs

=head1 SYNOPSIS

  package My::PSGI;
  
  use base Lemonldap::NG::Common::PSGI;
  
  # See Lemonldap::NG::Common::PSGI
  ...
  
  sub handler {
    my ( $self, $req ) = @_;
    # Do something and return a PSGI response
    # NB: $req is a Lemonldap::NG::Common::PSGI::Request object
    if ( $req->accept eq 'text/plain' ) { ... }
    
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Body lines' ] ];
  }

=head1 DESCRIPTION

This package provides HTTP request objects used by Lemonldap::NG PSGIs. It
contains common accessors to work with request

=head1 METHODS

=head2 Accessors

=head3 accept

'Accept' header content.

=head3 encodings

'Accept-Encoding' header content.

=head3 languages

'Accept-Language header content.

=head3 cookies

'Cookie' header content.

=head3 hostname

'Host' header content.

=head3 remote_ip

Client IP address.

=head3 port

Client TCP port.

=head3 method

HTTP method asked by client (GET/POST/PUT/DELETE).

=head3 scriptname

SCRIPT_NAME environment variable provided by HTTP server.

=head3 get_server_port

Server port.

=head3 path

PATH_INFO content which has been subtracted `scriptname`. So it's the relative
path_info for REST calls.

=head3 uri

REQUEST_URI environment variable.

=head3 unparsed_uri

Same as `uri` but without decoding.

=head3 user

REMOTE_USER environment variable. It contains username when a server authentication
is done.

=head3 userData

Hash reference to be used by Lemonldap::NG::Handler::PSGI. If a server authentication
is done, it contains:

  { _whatToTrace => `user()` }

=head3 params

GET parameters.

=head3 body

Content of POST requests

=head3 error

Set if an error occurs

=head3 contentType

Content type of posted datas.

=head3 contentLength

Length of posted datas.

=head2 Private accessors

=head3 _psgixBuffered

PSGI psgix.input.buffered variable.

=head3 _psgiInput

PSGI psgix.input variable.

=head2 Methods

=head3 jsonBodyToObj()

Get the content of a JSON POST request as Perl object.

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Handler>,
L<Plack>, L<PSGI>, L<Lemonldap::NG::Common::PSGI>,
L<Lemonldap::NG::Common::PSGI::Router>, L<HTML::Template>, 

=head1 AUTHORS

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2015-2016 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
