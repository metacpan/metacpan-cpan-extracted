package Lemonldap::NG::Common::PSGI::Request;

use strict;
use Mouse;
use JSON;
use Plack::Request;
use URI::Escape;

our $VERSION = '2.0.15';

our @ISA = ('Plack::Request');

#       http          ://  server   / path      ? query      # fragment
# m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

sub BUILD {
    my ( $self, $env ) = @_;
    foreach ( keys %$env ) {
        $self->{$_} ||= $env->{$_} if (/^(?:HTTP|SSL)_/);
    }
}

sub new {
    my $self = Plack::Request::new(@_);
    $self->env->{REQUEST_URI} = $self->env->{X_ORIGINAL_URI}
      if ( $self->env->{X_ORIGINAL_URI} );
    $self->env->{PATH_INFO} =~ s|//+|/|g;
    $self->env->{PATH_INFO} ||= '/';
    $self->env->{REQUEST_URI} =~ s|^//+|/|g;
    $self->{uri}         = uri_unescape( $self->env->{REQUEST_URI} );
    $self->{data}        = {};
    $self->{error}       = 0;
    $self->{respHeaders} = [];
    return bless( $self, $_[0] );
}

sub data { return $_[0]->{data} }

sub uri { return $_[0]->{uri} }

sub userData {
    my ( $self, $v ) = @_;
    return $self->{userData} = $v if ($v);
    return $self->{userData}
      || {
        ( $Lemonldap::NG::Handler::Main::tsv->{whatToTrace}
              || '_whatToTrace' ) => $self->{user}, };
}

sub respHeaders {
    my ( $self, $respHeaders ) = @_;
    $self->{respHeaders} = $respHeaders if ($respHeaders);
    return $self->{respHeaders};
}

sub spliceHdrs {
    my ($self) = @_;
    return splice @{ $self->{respHeaders} };
}

sub accept        { $_[0]->env->{HTTP_ACCEPT} }
sub encodings     { $_[0]->env->{HTTP_ACCEPT_ENCODING} }
sub languages     { $_[0]->env->{HTTP_ACCEPT_LANGUAGE} }
sub authorization { $_[0]->env->{HTTP_AUTHORIZATION} }
sub hostname      { $_[0]->env->{HTTP_HOST} }
sub origin        { $_[0]->env->{HTTP_ORIGIN} }
sub referer       { $_[0]->env->{REFERER} }
sub query_string  { $_[0]->env->{QUERY_STRING} }

sub error {
    my ( $self, $err ) = @_;
    $self->{error} = $err if ($err);
    return $self->{error};
}

*params = \&Plack::Request::param;

sub set_param {
    my ( $self, $k, $v ) = @_;
    $self->param;
    $self->env->{'plack.request.merged'}->{$k} =
      $self->env->{'plack.request.query'}->{$k} = $v;
}

sub wantJSON {
    return 1
      if ( defined $_[0]->accept
        and $_[0]->accept =~ m#(?:application|text)/json# );
    return 0;
}

# JSON parser
sub jsonBodyToObj {
    my $self = shift;
    return $self->{json_body} if ( $self->{json_body} );
    unless ( $self->content_type =~ /application\/json/ ) {
        $self->error('Data is not JSON');
        return undef;
    }
    unless ( $self->body ) {
        $self->error('No data');
        return undef;
    }
    my $j = eval { from_json( $self->content, { allow_nonref => 1 } ) };
    if ($@) {
        $self->error("$@$!");
        return undef;
    }
    return $self->{json_body} = $j;
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
contains common accessors to work with request. Note that it inherits from
L<Plack::Request>.

=head1 METHODS

All methods of L<Plack::Request> are available.
Lemonldap::NG::Common::PSGI::Request adds the following methods:

=head2 accept

'Accept' header content.

=head2 encodings

'Accept-Encoding' header content.

=head2 error

Used to store error value (usually a L<Lemonldap::NG::Portal::Main::Constants>
constant).

=head2 jsonBodyToObj

Get the content of a JSON POST request as Perl object.

=head2 languages

'Accept-Language header content.

=head2 hostname

'Host' header content.

=head2 read-body

Since body() methods returns an L<IO::Handle> object, this method reads and
return the request content as string.

=head2 respHeaders

Accessor to 'respHeaders' property. It is used to store headers that have to
be pushed in response (see L<Lemonldap::NG::Common::PSGI>).

Be careful, it contains an array reference, not a hash one because headers
can be multi-valued.

Example:

  # Set headers
  $req->respHeaders( "Location" => "http://x.y.z/", Etag => "XYZ", );
  # Add header
  $req->respHeaders->{"X-Key"} = "Value";

=head2 spliceHdrs

Returns headers array and flush it.

=head2 set_param( $key, $value )

L<Plack::Request> param() method is read-only. This method can be used to
modify a GET parameter value

=head2 uri

REQUEST_URI environment variable decoded.

=head2 user

REMOTE_USER environment variable. It contains username when a server
authentication is done.

=head2 userData

Hash reference to the session information (if app inherits from
L<Lemonldap::NG::Handler::PSGI> or any other handler PSGI package). If no
session information is available, it contains:

  { _whatToTrace => <REMOTE-USER value> }

=head2 wantJSON

Return true if current request ask JSON content (verify that "Accept" header
contains "application/json" or "text/json").

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Common::PSGI>,
L<Lemonldap::NG::Hander::PSGI>, L<Plack::Request>,
L<Lemonldap::NG::Portal::Main::Constants>,

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

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
