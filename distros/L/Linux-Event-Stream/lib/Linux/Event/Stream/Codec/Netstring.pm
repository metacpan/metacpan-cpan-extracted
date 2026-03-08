package Linux::Event::Stream::Codec::Netstring;
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
    # Find ':' separating length from payload.
    my $colon = index($$inref, ':');
    last if $colon < 0;

    my $len_s = substr($$inref, 0, $colon);
    return (0, 'invalid netstring length') if $len_s eq '' || $len_s =~ /\D/;

    my $len = 0 + $len_s;
    my $max = $self->{max_frame};
    if (defined($max) && $len > $max) {
      return (0, "frame too large (>$max bytes)");
    }

    my $need = $colon + 1 + $len + 1; # <len>:<payload>,
    last if length($$inref) < $need;

    return (0, 'invalid netstring terminator') if substr($$inref, $need - 1, 1) ne ',';

    my $payload = substr($$inref, $colon + 1, $len);
    substr($$inref, 0, $need, '');

    push @$outref, $payload;
  }

  return 1;
}

sub _encode ($self, $msg) {
  $msg = '' if !defined $msg;
  $msg = "$msg";
  return length($msg) . ':' . $msg . ',';
}

1;

__END__

=head1 NAME

Linux::Event::Stream::Codec::Netstring - Netstring framing codec

=head1 SYNOPSIS

  use Linux::Event::Stream;
  use Linux::Event::Stream::Codec::Netstring;

  my $codec = Linux::Event::Stream::Codec::Netstring->new(
    max_frame => 1024*1024,
  );

  my $s = Linux::Event::Stream->new(
    loop       => $loop,
    fh         => $fh,
    codec      => $codec,
    on_message => sub ($stream, $msg, $data) {
      # $msg is one netstring payload (binary-safe)
    },
  );

=head1 DESCRIPTION

This codec implements netstrings:

  <len>:<payload>,

where C<len> is an ASCII decimal length of C<payload> in bytes.

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
