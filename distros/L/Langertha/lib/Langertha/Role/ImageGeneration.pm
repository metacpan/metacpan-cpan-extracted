package Langertha::Role::ImageGeneration;
# ABSTRACT: Role for engines that support image generation
our $VERSION = '0.503';
use Moose::Role;
use Future::AsyncAwait;
use Carp qw( croak );
use Time::HiRes qw( gettimeofday tv_interval );
use Langertha::CallResult;

# simple_image_f sends through the engine's async backend (k292): injected
# client > Net::Async::HTTP > the sync LWP shim (ADR 0027).
with 'Langertha::Role::AsyncHTTP';


requires 'image_request';
requires 'simple_image';

has image_model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_image_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_image_model if $self->can('default_image_model');
  return $self->model;
}


async sub simple_image_f {
  my ( $self, $prompt, %extra ) = @_;
  my $request = $self->image_request($prompt, %extra);
  my $response = await $self->_async_do_request_f( request => $request );
  return $request->response_call->($response);
}


sub simple_image_result {
  my ( $self, $prompt, %extra ) = @_;
  my $model = exists $extra{model} ? $extra{model} : $self->image_model;
  my $request = $self->image_request($prompt, %extra);
  my $t0 = [gettimeofday];
  my $response = $self->user_agent->request($request);
  my $elapsed = tv_interval($t0);
  my $value = $request->response_call->($response);
  return Langertha::CallResult->from_http_response( $self, $response,
    value => $value, model => $model, total_seconds => $elapsed );
}


async sub simple_image_result_f {
  my ( $self, $prompt, %extra ) = @_;
  my $model = exists $extra{model} ? $extra{model} : $self->image_model;
  my $request = $self->image_request($prompt, %extra);
  my $t0 = [gettimeofday];
  my $response = await $self->_async_do_request_f( request => $request );
  my $elapsed = tv_interval($t0);
  my $value = $request->response_call->($response);
  return Langertha::CallResult->from_http_response( $self, $response,
    value => $value, model => $model, total_seconds => $elapsed );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ImageGeneration - Role for engines that support image generation

=head1 VERSION

version 0.503

=head1 DESCRIPTION

Engines that can generate images consume this role. It requires
C<image_request> and C<simple_image> methods, and provides an
C<image_model> attribute, the async L</simple_image_f> and
L</simple_image_result> / L</simple_image_result_f>.

=head2 image_model

The model name to use for image generation requests. Lazily defaults to
C<default_image_model> if the engine provides it, otherwise falls back
to the general C<model> attribute from L<Langertha::Role::Models>.

=head2 simple_image_f

    my $images = await $engine->simple_image_f('A cat in space', size => '1024x1024');

Async variant of C<simple_image>: same arguments, returns a L<Future> that
resolves to the same value (for the OpenAI dialect an ArrayRef of image
objects, see L<Langertha::Role::OpenAICompatible/image_response>) and fails
with the same error text. The request goes through the engine's async
backend (L<Langertha::Role::AsyncHTTP>), so
L<Langertha::Role::HTTP/user_agent_timeout> bounds it on
L<Net::Async::HTTP> too; without that module it runs synchronously over LWP.

=head2 simple_image_result

    my $result = $engine->simple_image_result('A cat in space');
    my $images = $result->value;
    say $result->usage->output_tokens if $result->has_usage;

Like C<simple_image>, but returns a L<Langertha::CallResult>: the same image
objects as C<value>, plus the provider's C<usage> (GPT image models report
tokens), this response's C<rate_limit>, the model and the measured
C<total_seconds>. Croaks like C<simple_image>.

=head2 simple_image_result_f

    my $result = await $engine->simple_image_result_f('A cat', size => '1024x1024');

Async variant of L</simple_image_result>, sent like L</simple_image_f>:
resolves to the L<Langertha::CallResult> and fails with the same error text.

=head1 SEE ALSO

=over

=item * L<Langertha::ImageGen> - Wrapper class for image generation with plugin support

=item * L<Langertha::Role::Models> - Model selection role

=item * L<Langertha::Plugin::Langfuse> - Observability plugin (hooks into image gen)

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
