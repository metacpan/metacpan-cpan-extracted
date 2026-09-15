package Linux::Event::Framer::Delimiter;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.114';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, $delimiter = undef, @args) {
    croak 'Delimiter requires a delimiter byte string' if !defined $delimiter;
    croak 'Delimiter must not be empty' if $delimiter eq '';
    croak 'Delimiter options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $include_delimiter = delete $opt{include_delimiter} // 0;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown Delimiter options: ' . join(', ', sort keys %opt) if %opt;

    my $native = {
        read_mode         => 2,
        delimiter         => $delimiter,
        include_delimiter => $include_delimiter ? 1 : 0,
        max_frame         => $max_frame,
    };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length exceeds max_frame=$config->{max_frame}"
        if defined($config->{max_frame}) && $length > $config->{max_frame};
    return $payload . $config->{delimiter};
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Delimiter - native delimiter framing declaration

=head1 SYNOPSIS

  package LineStream;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n"; # required delimiter

=head1 DESCRIPTION

Frames a byte stream at an arbitrary non-empty binary delimiter. Delimiters may
cross reads and multiple complete messages may be emitted from one read.
C<include_delimiter> defaults false. C<max_frame> optionally bounds payload
bytes before the delimiter. C<send> appends the configured delimiter.

=cut
