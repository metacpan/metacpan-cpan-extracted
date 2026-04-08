package Langertha::Usage;
# ABSTRACT: Immutable value object for LLM token usage with cross-provider conversion
our $VERSION = '0.400';
use Moose;
use Scalar::Util qw( blessed );

has input_tokens  => ( is => 'ro', isa => 'Int', default => 0 );
has output_tokens => ( is => 'ro', isa => 'Int', default => 0 );
has total_tokens  => ( is => 'ro', isa => 'Int', lazy => 1, builder => '_build_total_tokens' );

sub _build_total_tokens {
  my ($self) = @_;
  return $self->input_tokens + $self->output_tokens;
}

# Build a Usage from any of the wire-format hashrefs we know about.
sub from_hash {
  my ($class, $hash) = @_;
  return $class->new unless $hash && ref($hash) eq 'HASH';

  my $input  = $hash->{input_tokens};
  my $output = $hash->{output_tokens};
  my $total  = $hash->{total_tokens};

  $input  = $hash->{prompt_tokens}     if !defined $input  && defined $hash->{prompt_tokens};
  $input  = $hash->{prompt_eval_count} if !defined $input  && defined $hash->{prompt_eval_count};

  $output = $hash->{completion_tokens} if !defined $output && defined $hash->{completion_tokens};
  $output = $hash->{eval_count}        if !defined $output && defined $hash->{eval_count};

  $input  = 0 + ($input  // 0);
  $output = 0 + ($output // 0);

  my %args = ( input_tokens => $input, output_tokens => $output );
  $args{total_tokens} = 0 + $total if defined $total;
  return $class->new(%args);
}

# Build a Usage from any response shape: a Langertha::Response, a HashRef
# with a usage key, or undef.
sub from_response {
  my ($class, $response) = @_;
  return $class->new unless $response;

  if ( blessed($response) && $response->isa('Langertha::Response') ) {
    return $class->from_hash( $response->has_usage ? $response->usage : {} );
  }
  if ( ref($response) eq 'HASH' ) {
    return $class->from_hash( $response->{usage} || {} );
  }
  return $class->new;
}

# Immutable merge — returns a new Usage that is the sum of self + other.
sub merge {
  my ($self, $other) = @_;
  return $self unless $other;
  return ref($self)->new(
    input_tokens  => $self->input_tokens  + $other->input_tokens,
    output_tokens => $self->output_tokens + $other->output_tokens,
  );
}

# Canonical hash representation (input_tokens / output_tokens / total_tokens).
sub to_hash {
  my ($self) = @_;
  return {
    input_tokens  => $self->input_tokens,
    output_tokens => $self->output_tokens,
    total_tokens  => $self->total_tokens,
  };
}

sub to_openai_format {
  my ($self) = @_;
  return {
    prompt_tokens     => $self->input_tokens,
    completion_tokens => $self->output_tokens,
    total_tokens      => $self->total_tokens,
  };
}

sub to_anthropic_format {
  my ($self) = @_;
  return {
    input_tokens  => $self->input_tokens,
    output_tokens => $self->output_tokens,
  };
}

sub to_ollama_format {
  my ($self) = @_;
  return {
    prompt_eval_count => $self->input_tokens,
    eval_count        => $self->output_tokens,
  };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Usage - Immutable value object for LLM token usage with cross-provider conversion

=head1 VERSION

version 0.400

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

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
