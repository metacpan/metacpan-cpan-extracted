package Linux::Event::Framer::U32BE;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.116';

use Carp qw(croak);
use Linux::Event::Framer::LengthPrefix ();

sub _build_definition ($class, @args) {
    croak 'U32BE options must be key/value pairs' if @args % 2;
    my %opt = @args;
    croak 'bytes is fixed at 4 for U32BE' if exists $opt{bytes};
    croak 'endian is fixed at big for U32BE' if exists $opt{endian};
    return Linux::Event::Framer::LengthPrefix->_build_definition(
        %opt, bytes => 4, endian => 'big'
    );
}

1;

__END__

=head1 NAME

Linux::Event::Framer::U32BE - native 32-bit big-endian framing declaration

=head1 SYNOPSIS

  package MessageStream;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'U32BE',
      max_frame => 16 * 1024 * 1024; # optional

=head1 DESCRIPTION

Convenience declaration for a four-byte unsigned network-order payload length.
It accepts C<include_prefix> and C<max_frame>; width and byte order are fixed.

=cut
