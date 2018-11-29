package Hailo::Test::Tokenizer;
use v5.10.0;
use Moose;
use namespace::clean -except => 'meta';
use Hailo::Tokenizer::Words;

with 'Hailo::Role::Tokenizer';

sub make_tokens { goto &Hailo::Tokenizer::Words::make_tokens }
sub make_output { goto &Hailo::Tokenizer::Words::make_output }

__PACKAGE__->meta->make_immutable;
