package Linux::Event::Framer::Netstring;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.116';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'Netstring options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown Netstring options: ' . join(', ', sort keys %opt) if %opt;

    my $native = { read_mode => 5, max_frame => $max_frame };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length exceeds max_frame=$config->{max_frame}"
        if defined($config->{max_frame}) && $length > $config->{max_frame};
    return $length . ':' . $payload . ',';
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Netstring - native netstring framing declaration

=head1 SYNOPSIS

  package NetstringStream;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Netstring',
      max_frame => 1_048_576; # optional

=head1 DESCRIPTION

Parses canonical C<length:payload,> netstrings in XS. C<max_frame> optionally
bounds the payload. C<send> emits the canonical decimal encoding.

=cut
