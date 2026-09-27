package Linux::Event::HTTP::_HTTP2::ClientSelectorConnection;
use v5.36;
use strict;
use warnings;

use parent 'Linux::Event::HTTP::Client::Connection';

our $VERSION = '0.003';

sub _selector ($self) {
    return $self->{_http2_selector};
}

sub on_ready ($self) {
    my $selector = $self->_selector or return;
    $selector->_transport_ready($self);
    return;
}

sub on_error ($self, $error) {
    my $selector = $self->_selector;
    if ($selector
        && ($selector->protocol eq 'negotiating'
            || $selector->protocol eq 'selecting-h2')) {
        $selector->_transport_error($error);
        return;
    }
    return $self->SUPER::on_error($error);
}

sub on_eof ($self) {
    my $selector = $self->_selector;
    if ($selector
        && ($selector->protocol eq 'negotiating'
            || $selector->protocol eq 'selecting-h2')) {
        $selector->_transport_error(
            'unexpected EOF before HTTP protocol selection completed',
        );
        $self->close if !$self->is_closed;
        return;
    }
    return $self->SUPER::on_eof;
}

sub on_close ($self) {
    my $selector = $self->_selector;
    if ($selector
        && ($selector->protocol eq 'negotiating'
            || $selector->protocol eq 'selecting-h2')) {
        $selector->_transport_error(
            'HTTP connection closed before protocol selection completed',
        );
        return;
    }
    return $self->SUPER::on_close;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::_HTTP2::ClientSelectorConnection - private ALPN source connection

=cut
