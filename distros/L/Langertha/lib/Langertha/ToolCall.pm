package Langertha::ToolCall;
# ABSTRACT: Immutable canonical tool invocation emitted by an LLM
our $VERSION = '0.404';
use Moose;
use JSON::MaybeXS qw( encode_json decode_json );

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has arguments => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

# Provider-specific call id (may be empty if the upstream didn't supply one).
has id => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);

sub _decode_args {
  my ($args) = @_;
  return {} unless defined $args;
  return $args if ref($args) eq 'HASH';
  return {} unless length $args;
  my $decoded = eval { decode_json($args) };
  return ( ref($decoded) eq 'HASH' ) ? $decoded : {};
}

# --- Constructors from wire-format hashes ---

sub from_openai {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $fn = $hash->{function} || {};
  return undef unless ref($fn) eq 'HASH';
  my $name = $fn->{name} // '';
  return undef unless length $name;
  return $class->new(
    name      => $name,
    arguments => _decode_args( $fn->{arguments} ),
    id        => ( $hash->{id} // '' ),
  );
}

sub from_anthropic {
  my ($class, $block) = @_;
  return undef unless ref($block) eq 'HASH';
  return undef unless ( $block->{type} // '' ) eq 'tool_use';
  my $name = $block->{name} // '';
  return undef unless length $name;
  return $class->new(
    name      => $name,
    arguments => ( ref( $block->{input} ) eq 'HASH' ? $block->{input} : {} ),
    id        => ( $block->{id} // '' ),
  );
}

sub from_ollama {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $fn = $hash->{function} || {};
  return undef unless ref($fn) eq 'HASH';
  my $name = $fn->{name} // '';
  return undef unless length $name;
  return $class->new(
    name      => $name,
    arguments => _decode_args( $fn->{arguments} ),
    id        => ( $hash->{id} // '' ),
  );
}

# Pull every tool call out of an upstream response, in any of the formats
# we know about. Returns a list of ToolCall objects (possibly empty).
sub extract {
  my ($class, $raw) = @_;
  return () unless ref($raw) eq 'HASH';

  # OpenAI shape: choices[0].message.tool_calls
  if ( my $oai_msg = $raw->{choices}[0]{message} ) {
    if ( ref( $oai_msg->{tool_calls} ) eq 'ARRAY' ) {
      return grep { defined } map { $class->from_openai($_) } @{ $oai_msg->{tool_calls} };
    }
  }

  # Ollama shape: message.tool_calls
  if ( my $msg = $raw->{message} ) {
    if ( ref( $msg->{tool_calls} ) eq 'ARRAY' ) {
      return grep { defined } map { $class->from_ollama($_) } @{ $msg->{tool_calls} };
    }
  }

  # Anthropic shape: content[*] where type=tool_use
  if ( ref( $raw->{content} ) eq 'ARRAY' ) {
    return grep { defined } map { $class->from_anthropic($_) } @{ $raw->{content} };
  }

  return ();
}

# Hermes-style XML embedded in plain text. Returns ($cleaned_text, \@calls).
sub extract_hermes_from_text {
  my ($class, $text) = @_;
  my $clean = defined($text) ? $text : '';
  my @calls;
  while ( $clean =~ m{<tool_call>\s*(.*?)\s*</tool_call>}sg ) {
    my $json = $1;
    my $obj = eval { decode_json($json) };
    next unless ref($obj) eq 'HASH';
    next unless defined $obj->{name} && length $obj->{name};
    push @calls, $class->new(
      name      => $obj->{name},
      arguments => ( ref( $obj->{arguments} ) eq 'HASH' ? $obj->{arguments} : {} ),
    );
  }
  $clean =~ s{<tool_call>.*?</tool_call>}{}sg;
  $clean =~ s/^\s+|\s+$//g;
  return ( $clean, \@calls );
}

# --- Serializers to wire-format hashes ---

sub to_openai {
  my ($self, %opts) = @_;
  my $id = length( $self->id ) ? $self->id : ( $opts{fallback_id} // 'call_langertha' );
  return {
    id       => $id,
    type     => 'function',
    function => {
      name      => $self->name,
      arguments => encode_json( $self->arguments ),
    },
  };
}

sub to_anthropic_block {
  my ($self, %opts) = @_;
  my $id = length( $self->id ) ? $self->id : ( $opts{fallback_id} // 'toolu_langertha' );
  return {
    type  => 'tool_use',
    id    => $id,
    name  => $self->name,
    input => $self->arguments,
  };
}

sub to_ollama {
  my ($self) = @_;
  return {
    function => {
      name      => $self->name,
      arguments => $self->arguments,
    },
    ( length( $self->id ) ? ( id => $self->id ) : () ),
  };
}

sub to_hash {
  my ($self) = @_;
  return {
    id        => $self->id,
    name      => $self->name,
    arguments => $self->arguments,
  };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ToolCall - Immutable canonical tool invocation emitted by an LLM

=head1 VERSION

version 0.404

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
