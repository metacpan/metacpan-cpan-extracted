package MVC::Neaf::Request::CGI;

use strict;
use warnings;
our $VERSION = 0.17;

=head1 NAME

MVC::Neaf::Request::CGI - CGI driver for Not Even A Framework.

=head1 DESCRIPTION

Mostly useful for command-line based debugging via L<MVC::Neaf::CLI>.
However, a Neaf app can run as a CGI script (unless, of course, it relies on
in-memory storage somewhere).

See L<MVC::Neaf::Request> for the API. Nothing really interesting here.

L<CGI> is used internally.

=cut

use Carp;
use Encode;
use HTTP::Headers;

use parent qw(MVC::Neaf::Request);
use CGI;

=head2 new()

This will instantiate a CGI object and attach it to a Neaf request.

=cut

sub new {
    my ($class, %args) = @_;

    $args{driver} ||= CGI->new;
    $args{fd}     ||= \*STDOUT;
    $args{query_string} ||= $1
        if( ($args{driver}->request_uri || '') =~ m#.*?\?(.+)# );

    return bless \%args, $class;
};

=head2 do_get_client_ip()

=cut

sub do_get_client_ip {
    my $self = shift;

    return $self->{driver}->remote_addr;
};

=head2 do_get_method()

Return GET/POST.

=cut

sub do_get_method {
    my $self = shift;
    return $self->{driver}->request_method;
};

=head2 do_get_http_version

HTTP/1.0 or HTTP/1.1

B<NOTE> This currently returns based on the presence of Host header,
which is a HACK. Haven't found a better way yet...

=cut

sub do_get_http_version {
    my $req = shift;

    return $req->header_in("host") ? "1.1" : "1.0";
};

=head2 do_get_scheme

Returns http or https.

=cut

sub do_get_scheme {
    my $self = shift;
    my @arr = $self->{driver}->https;
    return @arr ? "https" : "http";
};

=head2 do_get_hostname

Returns server hostname.

=cut

sub do_get_hostname {
    my $self = shift;
    return $self->{driver}->server_name;
};

=head2 do_get_port

Returns server port.

=cut

sub do_get_port {
    my $self = shift;
    return $self->{driver}->server_port;
};

=head2 do_get_params

=cut

sub do_get_params {
    my $self = shift;

    my $q = $self->{driver};
    my %hash;
    foreach ($q->param) {
        $hash{$_} = $q->param($_);
    };
    return \%hash;
};

=head2 do_get_param_as_array

=cut

sub do_get_param_as_array {
    my ($self, $name) = @_;

    return $self->{driver}->param( $name );
};

=head2 do_get_path

=cut

sub do_get_path {
    my $self = shift;

    return $self->{driver}->script_name . $self->{driver}->path_info;
};

=head2 do_get_upload( "name" )

=cut

sub do_get_upload {
    my ($self, $id) = @_;

    my $filename = $self->{driver}->param($id);
    my $handle   = $self->{driver}->upload($id);

    return $handle ? { handle => $handle, filename => $filename } : ();
};

=head2 do_get_header_in

=cut

sub do_get_header_in {
    my $self = shift;

    my $head = HTTP::Headers->new;
    foreach ($self->{driver}->http) {
        $_ = lc $_;
        s/-/_/g;
        s/^http_//;
        my $raw = $self->{driver}->http( $_ );
        $raw = '' unless defined $raw;
        $head->header( $_ => [ split /, /, $raw ] );
    };

    return $head;
};

=head2 do_get_body()

=cut

sub do_get_body {
    my $self = shift;

    # TODO also check content-type header
    if ($self->method eq 'POST') {
        return $self->{driver}->param('POSTDATA');
    } elsif ($self->method eq 'PUT') {
        return $self->{driver}->param('PUTDATA');
    };

    return;
};

=head2 do_reply( $status, $content )

=cut

sub do_reply {
    my ($self, $status, $content) = @_;

    my $fd = $self->{fd};

    print $fd "Status: $status\n";
    print $fd $self->header_out->as_string;
    print $fd "\n";
    print $fd $content if defined $content;
    return;
};

=head2 do_write( $data )

Write to socket if async content serving is in use.

=cut


sub do_write {
    my ($self, $data) = @_;

    my $fd = $self->{fd};
    print $fd $data;
};

=head2 do_close()

Close client connection in async content mode.

=cut

sub do_close {
    my $self = shift;

    close $self->{fd};
};

1;
