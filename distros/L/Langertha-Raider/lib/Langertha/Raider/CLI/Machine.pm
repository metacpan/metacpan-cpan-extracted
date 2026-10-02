package Langertha::Raider::CLI::Machine;
# ABSTRACT: Internal writer of the raider CLI's machine output (JSON, MessagePack, YAML)
our $VERSION = '0.503';
use Moose;
use Moose::Util::TypeConstraints qw( enum );
use namespace::autoclean;
use Data::MessagePack;
use Encode qw( encode_utf8 );
use IO::Handle;
use JSON::MaybeXS ();
use Time::HiRes ();
use YAML::PP;



has format => (
  is       => 'ro',
  isa      => enum([qw( json msgpack yaml )]),
  required => 1,
);


has stream => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has version => (
  is      => 'ro',
  isa     => 'Int',
  default => 1,
);


has out => (
  is      => 'ro',
  default => sub { \*STDOUT },
);


has clock => (
  is      => 'ro',
  isa     => 'CodeRef',
  default => sub { \&Time::HiRes::time },
);


has max_content_length => (
  is      => 'ro',
  isa     => 'Int',
  default => 1000,
);

has _seq => (
  traits  => ['Counter'],
  is      => 'ro',
  isa     => 'Int',
  default => 0,
  handles => { _next_seq => 'inc' },
);


sub versions { (1) }


sub document {
  my ( $self, $status, %fields ) = @_;
  return { %fields, version => $self->version, status => $status };
}


sub event {
  my ( $self, $type, %payload ) = @_;
  return unless $self->stream;
  if ($type eq 'tool.result') {
    my $content = $payload{content} // '';
    my $max = $self->max_content_length;
    $payload{content}   = substr($content, 0, $max);
    $payload{truncated} = length $content > $max ? JSON::MaybeXS->true : JSON::MaybeXS->false;
  }
  $self->write({
    %payload,
    version => $self->version,
    type    => $type,
    seq     => $self->_next_seq,
    time    => $self->clock->(),
  });
  return;
}


sub finish {
  my ( $self, $doc ) = @_;
  return $self->event('run.finished', %$doc) if $self->stream;
  $self->write($doc);
  return;
}


sub write {
  my ( $self, $data ) = @_;
  my $out = $self->out;
  binmode $out, ':raw';
  print {$out} $self->encode($data);
  $out->flush;
  return;
}


sub encode {
  my ( $self, $data ) = @_;
  my $method = '_encode_'.$self->format;
  return $self->$method($self->normalize($data));
}


sub normalize {
  my ( $self, $data ) = @_;
  my $json = JSON::MaybeXS->new(canonical => 1, convert_blessed => 1, allow_nonref => 1);
  return $json->decode($json->encode($data));
}

sub _encode_json {
  my ( $self, $data ) = @_;
  my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1, $self->stream ? () : ( pretty => 1 ));
  return $self->stream ? $json->encode($data)."\n" : $json->encode($data);
}

sub _encode_msgpack {
  my ( $self, $data ) = @_;
  return Data::MessagePack->new->canonical(1)->utf8(1)->pack($self->_msgpack_booleans($data));
}

sub _encode_yaml {
  my ( $self, $data ) = @_;
  return encode_utf8(YAML::PP->new(boolean => 'JSON::PP', header => 1)->dump_string($data));
}

# Data::MessagePack refuses JSON::PP::Boolean; swap in its own booleans.
sub _msgpack_booleans {
  my ( $self, $data ) = @_;
  return { map { $_ => $self->_msgpack_booleans($data->{$_}) } keys %$data } if ref $data eq 'HASH';
  return [ map { $self->_msgpack_booleans($_) } @$data ] if ref $data eq 'ARRAY';
  return $data ? Data::MessagePack::true() : Data::MessagePack::false() if JSON::MaybeXS::is_bool($data);
  return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::Machine - Internal writer of the raider CLI's machine output (JSON, MessagePack, YAML)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $machine = Langertha::Raider::CLI::Machine->new(format => 'json', stream => 1);

    $machine->event('run.started', engine => 'openai', model => 'gpt-4o-mini');
    $machine->finish($machine->document(completed => response => 'hi', elapsed => 1));

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The machine output of F<raider> (ADR 0013): one format-independent model
-- the run's document and, when streaming, the events leading up to it --
written in one of three encodings. The model is built as plain Perl data;
L</encode> turns it into octets for the chosen L</format>. The reference of
the format itself is the POD of F<raider>.

Before encoding, the data is normalized through JSON, so a value is a
number, a string or a boolean exactly as the JSON encoding would write it --
the same fields and types in every encoding.

=head2 format

C<json>, C<msgpack> or C<yaml>. Required.

=head2 stream

True for the C<--stream-*> flags: L</event> writes every event, and
L</finish> writes the document as the C<run.finished> event. False writes
only the document, once, at L</finish>.

=head2 version

The format version written into the document and every event. Only C<1>
exists; see L</versions>.

=head2 out

Filehandle the octets are written to. Defaults to C<STDOUT>. It is switched
to C<:raw> before each write.

=head2 clock

Code reference returning the current time as epoch seconds, for the C<time>
of an event. Defaults to L<Time::HiRes/time>.

=head2 max_content_length

How many characters of a C<tool.result>'s text an event carries in
C<content>; a longer text is cut and the event flagged C<truncated>.
Defaults to C<1000>.

=head2 versions

    my @known = Langertha::Raider::CLI::Machine->versions;   # (1)

The format versions this raider can write.

=head2 document

    my $doc = $machine->document(completed => response => $text, metrics => $m, elapsed => $s);
    my $doc = $machine->document(failed => error => $message, elapsed => $s);

The document of a finished run: C<version>, C<status> and the given fields.

=head2 event

    $machine->event('tool.call', name => 'bash', arguments => { command => 'ls' });

Writes one event -- the payload plus C<version>, C<type>, C<seq> and C<time>
-- when L</stream> is on; does nothing otherwise. The C<content> of a
C<tool.result> is cut to L</max_content_length> characters, with
C<truncated> telling whether it was.

=head2 finish

    $machine->finish($doc);

Writes the run's document: as the C<run.finished> event when streaming (its
payload is the document), otherwise as the one document of the run.

=head2 write

Encodes the data with L</encode> and writes it to L</out>, flushed.

=head2 encode

    my $octets = $machine->encode($data);

The data normalized and encoded for L</format>: a pretty-printed canonical
JSON document or one compact line per event, a MessagePack object with text
as UTF-8 C<str>, or a YAML document starting with C<--->.

=head2 normalize

The data after a round trip through JSON: numbers, strings and booleans
(L<JSON::PP::Boolean>) as JSON sees them, text as characters.

=head1 SEE ALSO

=over

=item * L<raider>

=item * L<Langertha::Raider::CLI::Runner>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
