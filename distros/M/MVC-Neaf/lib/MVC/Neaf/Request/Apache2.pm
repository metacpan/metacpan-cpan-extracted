package MVC::Neaf::Request::Apache2;

use strict;
use warnings;

our $VERSION = 0.19;

=head1 NAME

MVC::Neaf::Request::Apache2 - Apache2 (mod_perl) driver for Not Even A Framework.

=head1 DESCRIPTION

Apache2 request that will invoke MVC::Neaf core functions from under mod_perl.

Much to the author's disgrace, this module currently uses
BOTH Apache2::RequestRec and Apache2::Request from libapreq.

=head1 SYNOPSIS

The following apache configuration should work with this module:

    LoadModule perl_module        modules/mod_perl.so
        PerlSwitches -I[% YOUR_LIB_DIRECTORY %]
    LoadModule apreq_module       [% modules %]/mod_apreq2.so

    # later...
    PerlModule MVC::Neaf::Request::Apache2
    PerlPostConfigRequire [% YOUR_APPLICATION %]
    <Location /[% SOME_URL_PREFIX %]>
        SetHandler perl-script
        PerlResponseHandler MVC::Neaf::Request::Apache2
    </Location>

=head1 METHODS

=cut

use Carp;
use URI::Escape;
use HTTP::Headers;
use Module::Load;

my %fail_apache;
BEGIN {
    foreach my $mod (qw(
        Apache2::RequestRec
        Apache2::RequestIO
        Apache2::Connection
        APR::SockAddr
        Apache2::Request
        Apache2::Upload
        Apache2::Const
    )) {
        eval { load $mod; 1 } and next;
        # warn "Failed to load $mod: $@";
        $fail_apache{$mod} = $@;
    };

    if ($ENV{MOD_PERL} && %fail_apache) {
        carp "$_ failed to load: $fail_apache{$_}"
            for keys %fail_apache;
        croak "Apache2 modules not loaded, refusing to run right away";
    };

    if (!%fail_apache) {
        Apache2::Const->import( -compile => 'OK' );
    };
};

use MVC::Neaf;
use parent qw(MVC::Neaf::Request);

=head2 do_get_client_ip

=cut

my $client_ip_name;
sub do_get_client_ip {
    my $self = shift;

    my $conn = $self->{driver_raw}->connection;
    if (!$client_ip_name) {
        # Apache 2.4 breaks API violently, so autodetect on first run,
        # fall back to localhost
        foreach (qw(remote_ip client_ip)) {
            $conn->can($_) or next;
            $client_ip_name = $_;
            last;
        };
        if (!$client_ip_name) {
            carp("WARNING: No client_ip found under Apache2, inform MVC::Neaf author");
            return '127.0.0.1';
        };
    };

    return $conn->$client_ip_name;
};

=head2 do_get_http_version

=cut

sub do_get_http_version {
    my $self = shift;
    my $proto = $self->{driver_raw}->proto_num;
    $proto =~ /^\D*(\d+?)\D*(\d\d?\d?)$/;
    return join ".", 0+$1, 0+$2;
};

=head2 do_get_scheme

=cut

sub do_get_scheme {
    my $self = shift;

    # Shamelessly stolen from Catalyst
    my $https = $self->{driver_raw}->subprocess_env('HTTPS');
    return( ($https && uc $https eq 'ON') ? "https" : "http" );
};

=head2 do_get_hostname

=cut

sub do_get_hostname {
    my $self = shift;
    return $self->{driver_raw}->hostname;
};

=head2 do_get_port()

=cut

sub do_get_port {
    my $self = shift;

    my $conn = $self->{driver_raw}->connection;
    return $conn->local_addr->port;
};

=head2 do_get_method()

=cut

sub do_get_method {
    my $self = shift;

    return $self->{driver_raw}->method;
};

=head2 do_get_path()

=cut

sub do_get_path {
    my $self = shift;

    return $self->{driver_raw}->uri;
};

=head2 do_get_params()

=cut

sub do_get_params {
    my $self = shift;

    my %hash;
    my $r = $self->{driver};
    $hash{$_} = $r->param($_) for $r->param;

    return \%hash;
};

=head2 do_get_param_as_array

=cut

sub do_get_param_as_array {
    my ($self, $name) = @_;

    return $self->{driver}->param( $name );
};

=head2 do_get_header_in()

=cut

sub do_get_header_in {
    my $self = shift;

    my %head;
    $self->{driver_raw}->headers_in->do( sub {
        my ($key, $val) = @_;
        push @{ $head{$key} }, $val;
    });

    return HTTP::Headers->new( %head );
};

=head2 do_get_upload( "name" )

Convert apache upload object into MCV::Neaf::Upload.

=cut

sub do_get_upload {
    my ($self, $name) = @_;

    my $r = $self->{driver};
    my $upload = $r->upload($name);

    return $upload ? {
        handle => $upload->fh,
        tempfile => $upload->tempname,
        filename => $upload->filename,
    } : ();
};

=head2 do_get_body

=cut

sub do_get_body {
    my $self = shift;

    # use Apache2::RequestIO
    # read until there's EOF, then concatenate & return
    my $r = $self->{driver_raw};

    my @buf = ('');
    while ( $r->read( $buf[-1], 8192, 0 ) ) {
        push @buf, '';
    };

    return join '', @buf;
};

=head2 do_reply( $status, $content )

=cut

sub do_reply {
    my ($self, $status, $content) = @_;

    my $r = $self->{driver_raw};

    my ($type) = $self->header_out->remove_header("content_type");
    $r->status( $status );
    $r->content_type( $type );

    my $head_backend = $r->headers_out;
    $self->header_out->scan( sub {
        $head_backend->add( $_[0], $_[1] );
    });

    return $r->print( $content );
};

=head2 do_write( $data )

Write to socket if async content serving is in use.

=cut

sub do_write {
    my ($self, $data) = @_;
    return $self->{driver_raw}->print( $data );
};

# TODO implement do_close, too!

=head2 handler( $apache_request )

A valid Apache2/mod_perl handler.

This invokes MCV::Neaf->handle_request when called.

Unfortunately, libapreq (in addition to mod_perl) is required currently.

=cut

sub handler : method {
    my ($class, $r) = @_;

    my $self = $class->new(
        driver_raw => $r,
        driver => Apache2::Request->new($r),
        query_string => $r->args,
    );
    if (!$MVC::Neaf::Request::query_allowed{ $r->method }) {
        $r->args('');
    };
    my $reply = MVC::Neaf->handle_request( $self );

    return Apache2::Const::OK();
};

=head2 failed_startup()

If Apache modules failed to load on startup, report error here.

This is done so because adding Apache2::* as dependencies would impose
a HUGE headache on PSGI users.

Ideally, this module should be mover out of the repository altogether.

=cut

sub failed_startup {
       return %fail_apache ? \%fail_apache : ();
};

1;
