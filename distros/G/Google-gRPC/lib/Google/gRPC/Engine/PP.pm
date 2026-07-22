package Google::gRPC::Engine::PP;

use strict;
use warnings;
use Moo;
use Protocol::HTTP2::Client;
use Carp qw(croak);

has on_headers      => ( is => 'rw' );
has on_data         => ( is => 'rw' );
has on_trailers     => ( is => 'rw' );
has on_stream_close => ( is => 'rw' );

has client => ( is => 'ro', lazy => 1, builder => '_build_client' );

sub _build_client {
    my ($self) = @_;
    return Protocol::HTTP2::Client->new(
        on_error => sub {
            my ($err) = @_;
        },
    );
}

sub is_xs {
    return 0;
}

sub send_ping {
    my ($self, $cb) = @_;
    if ($self->client->can('ping')) {
        $self->client->ping($cb);
    }
}

sub submit_request {
    my ($self, $args) = @_;
    my $headers_arr = $args->{headers} or croak 'headers is required';
    my $data        = $args->{data};
    my $end_stream  = $args->{end_stream};

    my %pseudo;
    my @normal_headers;

    for (my $i = 0; $i < @$headers_arr; $i += 2) {
        my $k = $headers_arr->[$i];
        my $v = $headers_arr->[$i + 1];
        if ($k =~ /^:(.*)$/) {
            $pseudo{':' . $1} = $v;
        }
        else {
            push @normal_headers, lc($k), $v;
        }
    }

    my $on_headers_cb  = $self->on_headers;
    my $on_data_cb     = $self->on_data;
    my $on_trailers_cb = $self->on_trailers;
    my $on_close_cb    = $self->on_stream_close;

    my $req_id;
    $req_id = $self->client->request(
        ':method'    => $pseudo{':method'} || 'POST',
        ':path'      => $pseudo{':path'} || '/',
        ':scheme'    => $pseudo{':scheme'} || 'https',
        ':authority' => $pseudo{':authority'} || 'localhost',
        headers      => \@normal_headers,
        defined($data) ? ( data => $data ) : (),
        on_headers => sub {
            my ($headers_ref) = @_;
            if ($on_headers_cb && defined $req_id) {
                $on_headers_cb->($req_id, $headers_ref);
            }
        },
        on_data => sub {
            my ($chunk) = @_;
            if ($on_data_cb && defined $req_id) {
                $on_data_cb->($req_id, $chunk);
            }
        },
        on_done => sub {
            my ($headers_ref, $body) = @_;
            if ($on_trailers_cb && $headers_ref && defined $req_id) {
                $on_trailers_cb->($req_id, $headers_ref);
            }
            if ($on_close_cb && defined $req_id) {
                $on_close_cb->($req_id, 0);
            }
        },
    );

    return $req_id;
}

sub feed_input {
    my ($self, $bytes) = @_;
    return unless defined $bytes && length($bytes);
    $self->client->feed($bytes);
}

sub get_output {
    my ($self) = @_;
    my $out = '';
    while (defined(my $frame = $self->client->next_frame)) {
        $out .= $frame;
    }
    return $out;
}


=head1 NAME

Google::gRPC::Engine::PP - gRPC Pure-Perl Transport Engine

=head1 SYNOPSIS

    use Google::gRPC::Engine::PP;

=head1 DESCRIPTION

This module provides grpc pure-perl transport engine functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
