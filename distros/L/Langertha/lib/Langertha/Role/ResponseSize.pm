package Langertha::Role::ResponseSize;
# ABSTRACT: Role for an engine where you can specify the response size (in tokens)
our $VERSION = '0.503';
use Moose::Role;

has response_size => (
  isa => 'Int',
  is => 'ro',
  predicate => 'has_response_size',
);


sub get_response_size {
  my ( $self ) = @_;
  return $self->response_size if $self->has_response_size;
  my $model_default = $self->_model_response_size_default;
  return $model_default if defined $model_default;
  return $self->default_response_size if $self->can('default_response_size');
  return;
}


# Default: no per-model defaults. Engines override with an ordered list of
# ( $matcher => $tokens ) pairs, matched against chat_model like
# Role::Capabilities' model_capability_corrections (ADR 0019 k225 Update).
sub model_response_size_defaults { return () }

sub _model_response_size_default {
  my ( $self ) = @_;
  my @defaults = $self->model_response_size_defaults;
  return unless @defaults && $self->can('chat_model');
  my $model = $self->chat_model // '';
  my $size;
  while ( @defaults >= 2 ) {
    my ( $matcher, $tokens ) = splice @defaults, 0, 2;
    my $hit = ref $matcher eq 'Regexp' ? ( $model =~ $matcher )
            :                            ( $model eq $matcher );
    $size = $tokens if $hit;   # later matching entries win
  }
  return $size;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ResponseSize - Role for an engine where you can specify the response size (in tokens)

=head1 VERSION

version 0.503

=head2 response_size

Maximum number of tokens to generate in the response. Optional. When not set,
the engine uses its own C<default_response_size> if available, or omits the
parameter from the request.

=head2 get_response_size

    my $size = $engine->get_response_size;

Returns the effective response size: the explicit C<response_size> if set,
otherwise the per-model default from L</model_response_size_defaults> for the
current C<chat_model>, otherwise the engine's C<default_response_size>,
otherwise C<undef>.

=head2 model_response_size_defaults

    sub model_response_size_defaults {
      return ( qr/\Akimi-k3(?!\d)/ => 16000 );
    }

Per-model default response size, used only when the caller set no
C<response_size>. Returns an B<ordered> list of C<< ( $matcher => $tokens ) >>
pairs; C<$matcher> is an exact model id (C<eq>) or a C<qr//> matched against
C<chat_model>, and later matching entries win. A matching entry replaces the
engine's C<default_response_size> for that model; it never overrides an
explicit C<response_size> or a per-request C<max_tokens>. The default returns
an empty list.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::ContextSize> - Limit total context tokens

=item * L<Langertha::Role::Temperature> - Sampling temperature

=back

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
