package Linux::Event::Framer::DecimalLength;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'DecimalLength options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $separator = delete $opt{separator} // ' ';
    croak 'separator must be exactly one byte'
        if bytes::length($separator) != 1;
    croak 'separator must not be an ASCII digit' if $separator =~ /[0-9]/;
    my $include_prefix = delete $opt{include_prefix} // 0;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown DecimalLength options: ' . join(', ', sort keys %opt) if %opt;

    my $native = {
        read_mode      => 7,
        delimiter      => $separator,
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
    return $length . $config->{delimiter} . $payload;
}

1;

__END__

=head1 NAME

Linux::Event::Framer::DecimalLength - native decimal-length framing declaration

=head1 SYNOPSIS

  package SyslogStream;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'DecimalLength',
      separator => ' ',       # default
      max_frame => 1_048_576; # optional

=head1 DESCRIPTION

Uses canonical ASCII decimal payload length followed by one non-digit separator
byte. The default wire form is C<5 HELLO>, matching RFC 6587 octet-counted
syslog. C<include_prefix> and C<max_frame> are supported. C<send> prepends the
configured decimal length and separator.

=cut
