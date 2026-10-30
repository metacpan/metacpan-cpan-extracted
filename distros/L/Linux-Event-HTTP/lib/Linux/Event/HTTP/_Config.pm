package Linux::Event::HTTP::_Config;
use v5.36;
use Unblock::HTTP 0.03 ();
use Unblock::HTTP1 0.13 ();
use Carp qw(croak);
use Scalar::Util qw(blessed);

sub loop ($loop) {
    croak 'new(): loop must be a Linux::Event::Loop'
        unless blessed($loop) && $loop->isa('Linux::Event::Loop');
}

sub stream_class ($option) {
    my $native = exists($option->{native_input}) ? delete($option->{native_input}) : 1;
    croak 'new(): native_input must be 0 or 1'
        unless defined($native) && !ref($native) && $native =~ /\A[01]\z/;
    return 'Linux::Event::HTTP::_Stream' unless $native;
    require Linux::Event::HTTP::_NativeStream;
    return 'Linux::Event::HTTP::_NativeStream';
}

sub protocols ($option) {
    my %protocols;
    for my $name (qw(http1 http2 http3)) {
        my $value = exists($option->{$name}) ? delete($option->{$name}) : ($name eq 'http1' ? 1 : 0);
        croak "new(): $name must be 0, 1 or a hash reference"
            unless ref($value) eq 'HASH' || (defined($value) && !ref($value) && $value =~ /\A[01]\z/);
        next unless ref($value) || $value;
        if ($name eq 'http3') {
            eval {
                require Unblock::HTTP3;
                Unblock::HTTP3->VERSION('0.14');
                require Net::QUIC;
                Net::QUIC->VERSION('0.06');
                1;
            } or croak "new(): http3 requires Unblock::HTTP3 >= 0.14 and Net::QUIC >= 0.06: $@";
        }
        if ($name eq 'http2') {
            eval { require Unblock::HTTP2; Unblock::HTTP2->VERSION('0.13'); 1 }
                or croak "new(): http2 requires Unblock::HTTP2 >= 0.13: $@";
        }
        $protocols{$name} = ref($value) ? $value : {};
    }
    return %protocols;
}

1;
