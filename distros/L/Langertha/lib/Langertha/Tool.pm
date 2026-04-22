package Langertha::Tool;
# ABSTRACT: Immutable canonical tool definition with cross-provider format conversion
our $VERSION = '0.404';
use Moose;

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has description => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);

has input_schema => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { { type => 'object', properties => {} } },
);

sub _empty_schema { { type => 'object', properties => {} } }

# --- Constructors from wire-format hashes ---

sub from_openai {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  return undef unless ($hash->{type} // '') eq 'function';
  my $fn = $hash->{function} || {};
  return undef unless ref($fn) eq 'HASH';
  my $name = $fn->{name} // '';
  return undef unless length $name;
  return $class->new(
    name         => $name,
    description  => ( $fn->{description} // '' ),
    input_schema => ( $fn->{parameters} || $class->_empty_schema ),
  );
}

sub from_anthropic {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $name = $hash->{name} // '';
  return undef unless length $name;
  return $class->new(
    name         => $name,
    description  => ( $hash->{description} // '' ),
    input_schema => ( $hash->{input_schema} || $hash->{parameters} || $class->_empty_schema ),
  );
}

# Generic: try OpenAI shape first, fall back to Anthropic.
sub from_hash {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  return $class->from_openai($hash) if ($hash->{type} // '') eq 'function';
  return $class->from_anthropic($hash);
}

# Build from a list of any-shape hashrefs and skip ones that don't parse.
sub from_list {
  my ($class, $list) = @_;
  return [] unless ref($list) eq 'ARRAY';
  my @out;
  for my $item (@$list) {
    my $tool = $class->from_hash($item);
    push @out, $tool if $tool;
  }
  return \@out;
}

# --- Serializers to wire-format hashes ---

sub to_openai {
  my ($self) = @_;
  return {
    type     => 'function',
    function => {
      name        => $self->name,
      description => $self->description,
      parameters  => $self->input_schema,
    },
  };
}

sub to_anthropic {
  my ($self) = @_;
  return {
    name         => $self->name,
    description  => $self->description,
    input_schema => $self->input_schema,
  };
}

sub to_ollama { $_[0]->to_openai }

# Canonical hash (matches the legacy Input::Tools->normalize_tools shape).
sub to_hash {
  my ($self) = @_;
  return {
    name         => $self->name,
    description  => $self->description,
    input_schema => $self->input_schema,
  };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Tool - Immutable canonical tool definition with cross-provider format conversion

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
