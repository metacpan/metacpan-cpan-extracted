package Linux::Event::Stream::Codec::U32BE;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.002';

use Carp qw(croak);

sub new ($class, %opt) {
  my $max_frame = delete $opt{max_frame};
  croak 'unknown options: ' . join(', ', sort keys %opt) if %opt;

  return bless {
    max_frame => $max_frame,
    decode    => \&_decode,
    encode    => \&_encode,
  }, $class;
}

sub _decode ($self, $inref, $outref) {
  while (1) {
    last if length($$inref) < 4;

    my $len = unpack('N', substr($$inref, 0, 4));

    my $max = $self->{max_frame};
    if (defined($max) && $len > $max) {
      return (0, "frame too large (>$max bytes)");
    }

    my $need = 4 + $len;
    last if length($$inref) < $need;

    my $payload = substr($$inref, 4, $len);
    substr($$inref, 0, $need, '');

    push @$outref, $payload;
  }

  return 1;
}

sub _encode ($self, $msg) {
  $msg = '' if !defined $msg;
  $msg = "$msg";
  return pack('N', length($msg)) . $msg;
}

1;

__END__

=head1 NAME

Linux::Event::Stream::Codec::U32BE - 32-bit big-endian length-prefix framing codec

=head1 SYNOPSIS

  use Linux::Event::Stream;
  use Linux::Event::Stream::Codec::U32BE;

  my $codec = Linux::Event::Stream::Codec::U32BE->new(
    max_frame => 1024*1024,
  );

  my $s = Linux::Event::Stream->new(
    loop       => $loop,
    fh         => $fh,
    codec      => $codec,
    on_message => sub ($stream, $msg, $data) {
      # $msg is one length-prefixed payload (binary-safe)
    },
  );

=head1 DESCRIPTION

Frames a byte stream into messages using a 32-bit big-endian length prefix:

  [u32be length][payload bytes...]

=head1 CONSTRUCTOR

=head2 new(%args)

=over 4

=item max_frame

Optional maximum allowed payload size in bytes.

=back

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
