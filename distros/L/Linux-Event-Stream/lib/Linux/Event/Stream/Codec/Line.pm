package Linux::Event::Stream::Codec::Line;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.002';

use Carp qw(croak);

sub new ($class, %opt) {
  my $chomp    = delete $opt{chomp} // 1;
  my $max_line = delete $opt{max_line};
  my $append_nl = delete $opt{append_newline} // 1;

  croak 'unknown options: ' . join(', ', sort keys %opt) if %opt;

  return bless {
    chomp          => $chomp,
    max_line       => $max_line,
    append_newline => $append_nl,

    decode => \&_decode,
    encode => \&_encode,
  }, $class;
}

sub _decode ($self, $inref, $outref) {
  # Consume complete lines ending with "\n".
  while (1) {
    my $idx = index($$inref, "\n");
    last if $idx < 0;

    my $max = $self->{max_line};
    if (defined($max) && $idx + 1 > $max) {
      return (0, "line too long (>$max bytes)");
    }

    my $line = substr($$inref, 0, $idx + 1, '');

    if ($self->{chomp}) {
      substr($line, -1, 1, '') if length($line) && substr($line, -1, 1) eq "\n";
    }

    push @$outref, $line;
  }

  return 1;
}

sub _encode ($self, $msg) {
  $msg = '' if !defined $msg;
  $msg = "$msg";

  if ($self->{append_newline}) {
    return $msg if length($msg) && substr($msg, -1, 1) eq "\n";
    return $msg . "\n";
  }

  return $msg;
}

1;

__END__

=head1 NAME

Linux::Event::Stream::Codec::Line - Newline-delimited framing codec

=head1 SYNOPSIS

  use Linux::Event::Stream;
  use Linux::Event::Stream::Codec::Line;

  my $codec = Linux::Event::Stream::Codec::Line->new(
    chomp    => 1,
    max_line => 64*1024,
  );

  my $s = Linux::Event::Stream->new(
    loop       => $loop,
    fh         => $fh,
    codec      => $codec,
    on_message => sub ($stream, $line, $data) {
      # $line is one message ("\n" removed when chomp => 1)
    },
  );

=head1 DESCRIPTION

This codec frames a byte stream into newline-delimited messages.

Decode behavior:

=over 4

=item *

Consumes complete messages ending in C<\n> from the input buffer.

=item *

If C<chomp> is true (default), the trailing newline is removed from each
message delivered to the application.

=item *

If C<max_line> is set, an error is raised if a newline is found beyond that
limit.

=back

Encode behavior:

=over 4

=item *

If C<append_newline> is true (default), C<\n> is appended unless the message
already ends with C<\n>.

=back

=head1 CONSTRUCTOR

=head2 new(%args)

=over 4

=item chomp

Boolean. Default true.

=item max_line

Optional maximum allowed bytes per line, including the delimiter.

=item append_newline

Boolean. Default true.

=back

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
