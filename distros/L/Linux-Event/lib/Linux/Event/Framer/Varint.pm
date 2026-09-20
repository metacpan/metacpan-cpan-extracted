package Linux::Event::Framer::Varint;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'Varint options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $include_prefix = delete $opt{include_prefix} // 0;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown Varint options: ' . join(', ', sort keys %opt) if %opt;

    my $native = {
        read_mode      => 6,
        include_prefix => $include_prefix ? 1 : 0,
        max_frame      => $max_frame,
    };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length exceeds max_frame=$config->{max_frame}"
        if defined($config->{max_frame}) && $length > $config->{max_frame};

    return pack('C', $length) . $payload if $length < 128;

    my @octets;
    my $value = $length;
    do {
        my $byte = $value & 0x7f;
        $value >>= 7;
        $byte |= 0x80 if $value;
        push @octets, $byte;
    } while ($value);
    return pack('C*', @octets) . $payload;
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Varint - native unsigned LEB128 framing declaration

=head1 SYNOPSIS

  package CompactStream;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Varint',
      max_frame => 1_048_576; # optional

=head1 DESCRIPTION

Uses a canonical unsigned LEB128 payload-length prefix. C<include_prefix>
controls inbound delivery and C<max_frame> bounds payload length. C<send>
prepends the canonical variable-width encoding.

=cut
