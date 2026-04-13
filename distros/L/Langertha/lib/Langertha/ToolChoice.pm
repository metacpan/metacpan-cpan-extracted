package Langertha::ToolChoice;
# ABSTRACT: Immutable canonical tool-selection policy with cross-provider conversion
our $VERSION = '0.401';
use Moose;
use Moose::Util::TypeConstraints qw( enum );

# Canonical types: 'auto' (let model decide), 'any' (must call any tool),
# 'none' (no tool calling), 'tool' (must call this specific tool).
enum 'Langertha::ToolChoice::Type' => [qw( auto any none tool )];

has type => (
  is       => 'ro',
  isa      => 'Langertha::ToolChoice::Type',
  required => 1,
);

has name => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  default   => sub { undef },
);

# --- Convenience constructors ---

sub auto     { my $class = shift; $class->new( type => 'auto' ) }
sub any      { my $class = shift; $class->new( type => 'any' ) }
sub none     { my $class = shift; $class->new( type => 'none' ) }
sub specific {
  my ( $class, $name ) = @_;
  return $class->new( type => 'tool', name => $name );
}

# --- Constructors from wire-format hashes/strings ---

sub from_hash {
  my ($class, $val) = @_;
  return undef unless defined $val;

  if ( !ref($val) ) {
    return $class->any  if $val eq 'required';
    return $class->auto if $val eq 'auto';
    return $class->none if $val eq 'none';
    return undef;
  }

  return undef unless ref($val) eq 'HASH';
  my $type = $val->{type} // '';

  if ( $type eq 'function' ) {
    my $name = '';
    if ( ref( $val->{function} ) eq 'HASH' ) {
      $name = $val->{function}{name} // '';
    } elsif ( defined $val->{name} ) {
      $name = $val->{name} // '';
    }
    return length($name) ? $class->specific($name) : $class->auto;
  }

  if ( $type eq 'tool' ) {
    my $name = $val->{name} // '';
    return length($name) ? $class->specific($name) : $class->auto;
  }

  return $class->any  if $type eq 'any';
  return $class->auto if $type eq 'auto';
  return $class->none if $type eq 'none';
  return undef;
}

sub from_openai    { shift->from_hash(@_) }
sub from_anthropic { shift->from_hash(@_) }

# --- Serializers ---

sub to_openai {
  my ($self) = @_;
  return 'required' if $self->type eq 'any';
  return 'auto'     if $self->type eq 'auto';
  return 'none'     if $self->type eq 'none';
  if ( $self->type eq 'tool' ) {
    return defined $self->name && length $self->name
      ? { type => 'function', function => { name => $self->name } }
      : 'auto';
  }
  return undef;
}

sub to_anthropic {
  my ($self) = @_;
  return { type => 'any' }  if $self->type eq 'any';
  return { type => 'auto' } if $self->type eq 'auto';
  return { type => 'none' } if $self->type eq 'none';
  if ( $self->type eq 'tool' ) {
    return defined $self->name && length $self->name
      ? { type => 'tool', name => $self->name }
      : { type => 'auto' };
  }
  return undef;
}

sub to_hash {
  my ($self) = @_;
  return { type => $self->type, ( defined $self->name ? ( name => $self->name ) : () ) };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ToolChoice - Immutable canonical tool-selection policy with cross-provider conversion

=head1 VERSION

version 0.401

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
