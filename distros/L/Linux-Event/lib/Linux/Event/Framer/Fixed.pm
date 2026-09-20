package Linux::Event::Framer::Fixed;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'Fixed options must be key/value pairs' if @args != 1 && @args % 2;
    my %opt = @args == 1 ? (size => $args[0]) : @args;
    my $size = delete $opt{size};
    croak 'Fixed requires size' if !defined $size;
    croak 'size must be a positive integer'
        if $size !~ /\A\d+\z/ || $size <= 0;
    croak 'unknown Fixed options: ' . join(', ', sort keys %opt) if %opt;

    my $native = { read_mode => 3, fixed_size => 0 + $size };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length does not equal fixed size $config->{fixed_size}"
        if $length != $config->{fixed_size};
    return $payload;
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Fixed - native fixed-size framing declaration

=head1 SYNOPSIS

  package RecordStream;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Fixed',
      size => 32; # required

=head1 DESCRIPTION

Emits exactly C<size> bytes per message. C<send> rejects payloads whose byte
length differs from the configured positive size.

=cut
