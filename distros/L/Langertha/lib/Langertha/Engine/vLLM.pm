package Langertha::Engine::vLLM;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: vLLM inference server
$Langertha::Engine::vLLM::VERSION = '0.005';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAI';

has '+url' => (
  required => 1,
);

sub default_model { croak "".(ref $_[0])." requires a default_model" }

sub _build_api_key { 'vllm' }

sub _build_supported_operations {[qw(
  createChatCompletion
  createCompletion
)]}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::vLLM - vLLM inference server

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Langertha::Engine::vLLM;

  my $vllm = Langertha::Engine::vLLM->new(
    url => $ENV{VLLM_URL},
    model => $ENV{VLLM_MODEL},
    system_prompt => 'You are a helpful assistant',
  );

  print($vllm->simple_chat('Say something nice'));

=head1 DESCRIPTION

B<THIS API IS WORK IN PROGRESS>

=head1 HOW TO INSTALL VLLM

L<https://docs.vllm.ai/en/latest/getting_started/installation.html>

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
