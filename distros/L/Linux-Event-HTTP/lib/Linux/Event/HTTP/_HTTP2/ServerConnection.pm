package Linux::Event::HTTP::_HTTP2::ServerConnection;
use v5.36;
use strict;
use warnings;

use parent 'Linux::Event::IO::Sock::Stream';

our $VERSION = '0.003';

sub on_data ($self, $bytes) {
    my $executor = $self->{_http2_executor}
        or die 'HTTP/2 server connection has no executor';

    my $ok = eval {
        $executor->input($bytes);
        1;
    };
    if (!$ok) {
        my $error = "$@";
        $error =~ s/\s+\z//;
        $executor->close if $executor->can('close');
        delete $self->{_http2_executor};
        $self->close if !$self->is_closed;
    }
    return;
}

sub on_close ($self) {
    if (my $executor = delete $self->{_http2_executor}) {
        $executor->close;
    }
    return;
}

sub transaction ($self) {
    my $executor = $self->{_http2_executor} or return undef;
    return $executor->transaction;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::_HTTP2::ServerConnection - private HTTP/2 Stream target

=head1 DESCRIPTION

This private class is the raw Linux::Event Stream descriptor used after TLS ALPN
selects HTTP/2. Protocol state lives in the composed _HTTP2::Server executor.

=cut
