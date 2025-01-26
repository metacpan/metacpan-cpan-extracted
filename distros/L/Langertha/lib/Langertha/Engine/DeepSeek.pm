package Langertha::Engine::DeepSeek;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: DeepSeek API
$Langertha::Engine::DeepSeek::VERSION = '0.007';
use Moose;
extends 'Langertha::Engine::OpenAI';
use Carp qw( croak );

sub _build_supported_operations {[qw(
  createChatCompletion
)]}

sub all_models {qw(
  deepseek-chat
  deepseek-reasoner
)}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.deepseek.com' },
);
around has_url => sub { 1 };

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_DEEPSEEK_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_DEEPSEEK_API_KEY or api_key set";
}

sub default_model { 'deepseek-chat' }

sub embedding_request {
  croak "".(ref $_[0])." doesn't support embedding";
}

sub transcription_request {
  croak "".(ref $_[0])." doesn't support transcription";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::DeepSeek - DeepSeek API

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  use Langertha::Engine::DeepSeek;

  my $deepseek = Langertha::Engine::DeepSeek->new(
    api_key => $ENV{DEEPSEEK_API_KEY},
    system_prompt => 'You are a helpful assistant',
    temperature => 0.5,
  );

  print($deepseek->simple_chat('Say something nice'));

=head1 DESCRIPTION

B<THIS API IS WORK IN PROGRESS>

=head1 HOW TO GET DEEPSEEK API KEY

L<https://platform.deepseek.com/>

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
