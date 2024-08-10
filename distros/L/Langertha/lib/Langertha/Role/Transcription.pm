package Langertha::Role::Transcription;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for APIs with transcription functionality
$Langertha::Role::Transcription::VERSION = '0.002';
use Moose::Role;
use Carp qw( croak );

requires qw(
  transcription_request
  transcription_response
);

has transcription_model => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_transcription_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_transcription_model if $self->can('default_transcription_model');
  return $self->model;
}

sub transcription {
  my ( $self, $file_or_content, %extra ) = @_;
  return $self->transcription_request($file_or_content, %extra);
}

sub simple_transcription {
  my ( $self, $file_or_content, %extra ) = @_;
  my $request = $self->transcription($file_or_content, %extra);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Transcription - Role for APIs with transcription functionality

=head1 VERSION

version 0.002

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/langertha>

  git clone https://github.com/Getty/langertha.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
