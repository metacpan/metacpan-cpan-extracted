package Linux::Event::HTTP::_Stream;
use v5.36;
use parent 'Linux::Event::HTTP::_Transport';
sub on_data ($self, $bytes) {
    my $engine = $self->{http_engine};
    if ($engine && $engine->want_read) {
        my $ok = eval { $engine->input($bytes); 1 };
        $self->_http_input_failed("$@") unless $ok;
        $self->_http_maybe_finish if $ok && $self->{http_multiplexed};
    }
    return;
}
1;
