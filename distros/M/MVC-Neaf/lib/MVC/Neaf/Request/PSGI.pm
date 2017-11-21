package MVC::Neaf::Request::PSGI;

use strict;
use warnings;
our $VERSION = 0.18;

=head1 NAME

MVC::Neaf::Request::PSGI - Not Even A Framework: PSGI driver.

=head1 METHODS

=cut

use URI::Escape qw(uri_unescape);
use Encode;
use Plack::Request;

use parent qw(MVC::Neaf::Request);

=head2 new( env => $psgi_input )

Constructor. C<env> MUST follow L<PSGI> requirements.

=cut

my %default_env = (
    REQUEST_METHOD => 'GET',
);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new( @_ );

    # Don't modify env!
    # Remove query string if not GET|HEAD
    # so that GET params are not available inside POST by default
    my $env = $self->{env} || \%default_env;
    $self->{query_string} = $env->{QUERY_STRING};

    $self->{driver} ||= Plack::Request->new({
        REQUEST_METHOD => 'GET',
        %$env,
        ($MVC::Neaf::Request::query_allowed{ $env->{REQUEST_METHOD} || 'GET' }
            ? () : (QUERY_STRING => '')),
    });

    return $self;
};

=head2 do_get_client_ip

=cut

sub do_get_client_ip {
    my $self = shift;

    return $self->{driver}->address;
};

=head2 do_get_http_version()

=cut

sub do_get_http_version {
    my $self = shift;

    my $proto = $self->{driver}->protocol || '1.0';
    $proto =~ s#^HTTP/##;

    return $proto;
};

=head2 do_get_scheme()

=cut

sub do_get_scheme {
    my $self = shift;
    return $self->{driver}->scheme;
};

=head2 do_get_hostname()

=cut

sub do_get_hostname {
    my $self = shift;
    my $base = $self->{driver}->base;

    return $base =~ m#//([^:?/]+)# ? $1 : "localhost";
};

=head2 do_get_port()

=cut

sub do_get_port {
    my $self = shift;
    my $base = $self->{driver}->base;

    return $base =~ m#//([^:?/]+):(\d+)# ? $2 : "80";
};

=head2 do_get_method()

Return GET/POST.

=cut

sub do_get_method {
    my $self = shift;
    return $self->{driver}->method;
};

=head2 do_get_path()

Returns the path part of URI.

=cut

sub do_get_path {
    my $self = shift;

    my $path = $self->{env}{REQUEST_URI};
    $path = '' unless defined $path;

    $path =~ s#\?.*$##;
    $path =~ s#^/*#/#;

    return $path;
};

=head2 do_get_params()

Returns GET/POST parameters as a hash.

B<CAVEAT> Plack::Request's multivalue hash params are ignored for now.

=cut

sub do_get_params {
    my $self = shift;

    my %hash;
    foreach ( $self->{driver}->param ) {
        $hash{$_} = $self->{driver}->param( $_ );
    };

    return \%hash;
};

=head2 do_get_param_as_array

=cut

sub do_get_param_as_array {
    my ($self, $name) = @_;

    return $self->{driver}->param( $name );
};

=head2 do_get_upload( "name" )

B<NOTE> This garbles Hash::Multivalue.

=cut

sub do_get_upload {
    my ($self, $id) = @_;

    $self->{driver_upload} ||= $self->{driver}->uploads;
    my $up = $self->{driver_upload}{$id}; # TODO 0.90 don't garble multivalues

    return $up ? { tempfile => $up->path, filename => $up->filename } : ();
};

=head2 do_get_header_in

=cut

sub do_get_header_in {
    my $self = shift;

    return $self->{driver}->headers;
};

=head2 do_get_body

=cut

sub do_get_body {
    my $self = shift;

    return $self->{driver}->content;
};

=head2 do_reply( $status_line, \%headers, $content )

Send reply to client. Not to be used directly.

B<NOTE> This function just returns its input and has no side effect,
rather relying on PSGI calling conventions.

=cut

sub do_reply {
    my ($self, $status, $content) = @_;

    my @header_array;
    $self->header_out->scan( sub {
            push @header_array, encode_utf8($_[0]), encode_utf8($_[1]);
    });

    # HACK - we're being returned by handler in MVC::Neaf itself in case of
    # PSGI being used.

    if ($self->{response}{postponed}) {
        # Even hackier HACK. If we have a postponed action,
        # we must use PSGI functional interface to ensure
        # reply is sent to client BEFORE
        # postponed calls get executed.

        return sub {
            my $responder = shift;

            # TODO 0.90 should handle responder's failure somehow
            $self->{writer} = $responder->( [ $status, \@header_array ] );
            $self->{writer}->write( $content ) if defined $content;

            # Now we may need to output more stuff
            # So save writer inside self for callbacks to write to
            $self->execute_postponed;
            # close was not called by 1 of callbacks
            $self->do_close if $self->{continue};
        };
    };

    # Otherwise just return plain data.
    return [ $status, \@header_array, [ $content ]];
};

=head2 do_write( $data )

Write to socket in async content mode.

=cut

sub do_write {
    my ($self, $data) = @_;

    return unless defined $data;

    # NOTE "can't call method write on undefined value" here
    # probably means that PSGI responder failed unexpectedly in do_reply()
    # and we didn't handle it properly and got empty {writer}
    # and the request is being destroyed.
    $self->{writer}->write( $data );
    return 1;
};

=head2 do_close()

Close client connection in async content mode.

=cut

sub do_close {
    my $self = shift;

    $self->{writer}->close;
};

1;
