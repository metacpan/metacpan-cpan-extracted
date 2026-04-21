package Langertha::Role::Embedding;
# ABSTRACT: Role for APIs with embedding functionality
our $VERSION = '0.402';
use Moose::Role;
use Carp qw( croak );
use Log::Any qw( $log );

requires qw(
  embedding_request
  embedding_response
);

has embedding_model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_embedding_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_embedding_model if $self->can('default_embedding_model');
  return $self->model;
}


sub embedding {
  my ( $self, $text ) = @_;
  return $self->embedding_request($text);
}


sub simple_embedding {
  my ( $self, $text ) = @_;
  $log->debugf("[%s] simple_embedding, model=%s, input_length=%d",
    ref $self, $self->embedding_model // 'default', length($text // ''));
  my $request = $self->embedding($text);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Embedding - Role for APIs with embedding functionality

=head1 VERSION

version 0.402

=head2 embedding_model

The model name to use for embedding requests. Lazily defaults to
C<default_embedding_model> if the engine provides it, otherwise falls back
to the general C<model> attribute from L<Langertha::Role::Models>.

=head2 embedding

    my $request = $engine->embedding($text);

Builds and returns an embedding HTTP request object for the given C<$text>.
Use L</simple_embedding> to execute the request and get the result directly.

=head2 simple_embedding

    my $vector = $engine->simple_embedding($text);

Sends an embedding request for C<$text> and returns the embedding vector.
Blocks until the request completes.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::HTTP> - HTTP transport layer

=item * L<Langertha::Role::Models> - Model selection (provides C<embedding_model>)

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
