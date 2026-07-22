package Google::gRPC::ChannelPool;

use strict;
use warnings;
use Moo;
use Google::gRPC::Channel;
use Google::gRPC::Framing;
use Socket qw(getaddrinfo NI_NUMERICHOST SOCK_STREAM);
use Carp qw(croak);

has target       => ( is => 'ro', required => 1 );
has auth_token   => ( is => 'ro', required => 0 );
has engine_type  => ( is => 'ro', required => 0 );
has resolved_ips => ( is => 'ro', required => 0 );
has subchannels  => ( is => 'rw', default => sub { [] } );
has rr_index     => ( is => 'rw', default => sub { 0 } );
has metrics      => ( is => 'rw', default => sub { {} } );

sub BUILD {
    my ($self) = @_;
    $self->_init_pool();
}

sub _init_pool {
    my ($self) = @_;

    my $target_str = $self->target;
    my ($host, $port);

    if ($target_str =~ /^\[([a-fA-F0-9:]+)\](?::(\d+))?$/) {
        $host = $1;
        $port = $2 || '443';
    } elsif ($target_str =~ /^([^:]+):(\d+)$/) {
        $host = $1;
        $port = $2;
    } else {
        $host = $target_str;
        $port = '443';
    }

    my @ips;
    if ($self->resolved_ips && @{$self->resolved_ips}) {
        @ips = @{$self->resolved_ips};
    } else {
        my ($err, @res) = getaddrinfo($host, $port, { socktype => SOCK_STREAM });
        if (!$err && @res) {
            my %seen;
            for my $r (@res) {
                my ($err_name, $ip) = Socket::getnameinfo($r->{addr}, NI_NUMERICHOST);
                if (!$err_name && $ip && !$seen{$ip}++) {
                    push @ips, $ip;
                }
            }
        }
        if (!@ips) {
            push @ips, $host;
        }
    }

    my @pool;
    my %initial_metrics;

    for my $ip (@ips) {
        my $sub_target;
        if ($ip =~ /:/ && $ip !~ /^\[/) {
            $sub_target = '[' . $ip . ']:' . $port;
        } elsif ($ip =~ /:\d+$/) {
            $sub_target = $ip;
        } else {
            $sub_target = $ip . ':' . $port;
        }

        my %chan_args = (
            target => $sub_target,
        );
        $chan_args{auth_token} = $self->auth_token if $self->auth_token;
        $chan_args{engine_type} = $self->engine_type if $self->engine_type;

        my $channel = Google::gRPC::Channel->new(%chan_args);
        push @pool, $channel;

        $initial_metrics{$ip} = {
            requests       => 0,
            bytes_sent     => 0,
            bytes_received => 0,
            total_bytes    => 0,
            target         => $sub_target,
        };
    }

    $self->subchannels(\@pool);
    $self->metrics(\%initial_metrics);
}

sub get_channel {
    my ($self) = @_;
    my $subs = $self->subchannels;
    return unless @$subs;

    my $idx = $self->rr_index % scalar(@$subs);
    $self->rr_index($self->rr_index + 1);
    return $subs->[$idx];
}

sub record_request {
    my ($self, $ip_key, $bytes) = @_;
    $bytes //= 0;
    if (!exists $self->metrics->{$ip_key}) {
        $self->metrics->{$ip_key} = {
            requests       => 0,
            bytes_sent     => 0,
            bytes_received => 0,
            total_bytes    => 0,
            target         => $ip_key,
        };
    }
    $self->metrics->{$ip_key}{requests}++;
    $self->metrics->{$ip_key}{bytes_sent} += $bytes;
    $self->metrics->{$ip_key}{total_bytes} += $bytes;
}

sub record_response {
    my ($self, $ip_key, $bytes) = @_;
    $bytes //= 0;
    if (!exists $self->metrics->{$ip_key}) {
        $self->metrics->{$ip_key} = {
            requests       => 0,
            bytes_sent     => 0,
            bytes_received => 0,
            total_bytes    => 0,
            target         => $ip_key,
        };
    }
    $self->metrics->{$ip_key}{bytes_received} += $bytes;
    $self->metrics->{$ip_key}{total_bytes} += $bytes;
}

sub _extract_ip_key {
    my ($self, $channel_target) = @_;
    my $ip_key = $channel_target;
    if ($ip_key =~ /^\[([a-fA-F0-9:]+)\](?::\d+)?$/) {
        $ip_key = $1;
    } elsif ($ip_key =~ /^([^:]+):\d+$/) {
        $ip_key = $1;
    }
    return $ip_key;
}

sub create_stream {
    my ($self, %opts) = @_;
    my $channel = $self->get_channel();
    croak 'No available channels in pool' unless $channel;

    my $ip_key = $self->_extract_ip_key($channel->target);

    my $req_bytes = 0;
    if (defined $opts{request}) {
        my $raw_payload = ref($opts{request}) && $opts{request}->can('serialize') ? $opts{request}->serialize() : $opts{request};
        $req_bytes = length(Google::gRPC::Framing::pack_frame($raw_payload));
    }

    $self->record_request($ip_key, $req_bytes);

    my $orig_on_message = $opts{on_message};
    $opts{on_message} = sub {
        my ($stream, $msg) = @_;
        my $resp_bytes = 0;
        if (defined $msg) {
            my $raw = ref($msg) && $msg->can('serialize') ? $msg->serialize() : $msg;
            $resp_bytes = length(Google::gRPC::Framing::pack_frame($raw));
        }
        $self->record_response($ip_key, $resp_bytes);
        if ($orig_on_message) {
            $orig_on_message->($stream, $msg);
        }
    };

    my $stream = $channel->create_stream(%opts);
    if ($stream->can('pool')) {
        $stream->pool($self);
        $stream->ip_key($ip_key);
    }

    return $stream;
}

sub get_metrics {
    my ($self, $key) = @_;
    if (defined $key) {
        if (exists $self->metrics->{$key}) {
            return $self->metrics->{$key};
        }
        my $ip_key = $self->_extract_ip_key($key);
        if (exists $self->metrics->{$ip_key}) {
            return $self->metrics->{$ip_key};
        }
        return undef;
    }
    return $self->metrics;
}

sub reset_metrics {
    my ($self) = @_;
    for my $key (keys %{$self->metrics}) {
        $self->metrics->{$key} = {
            requests       => 0,
            bytes_sent     => 0,
            bytes_received => 0,
            total_bytes    => 0,
            target         => $self->metrics->{$key}{target},
        };
    }
}


=head1 NAME

Google::gRPC::ChannelPool - gRPC Channel Pool Management

=head1 SYNOPSIS

    use Google::gRPC::ChannelPool;

=head1 DESCRIPTION

This module provides grpc channel pool management functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
