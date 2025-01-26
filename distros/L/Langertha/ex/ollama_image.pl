#!/usr/bin/env perl
# ABSTRACT: Ollama image upload example

$|=1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;
use Data::Dumper;
use Path::Tiny;
use Carp qw( croak );
use MIME::Base64;

use Langertha::Engine::Ollama;

my @images = @ARGV;

{
  if ($ENV{OLLAMA_URL}) {
    my $start = time;

    my $model = $ENV{OLLAMA_MODEL} || 'llava:latest';

    my $ollama = Langertha::Engine::Ollama->new(
      url => $ENV{OLLAMA_URL},
      model => $model,
      keep_alive => 1,
      system_prompt => <<__EOP__,

Write a straightforward description of each image for a text-to-image generation dataset, as simple as a dataset would expect. Only describe what is visible in the image, without including any information about what is not there, context, or metadata. The description should be brief and focused, just as a dataset requires.

__EOP__
    );

    my @base64_images;

    for my $image (@images) {
      my $pi = path($image);
      croak "Image must exist" unless $pi->exists and $pi->is_file;
      push @base64_images, encode_base64($pi->slurp_raw);
    }

    my $answer = $ollama->simple_chat({
      role => 'user',
      content => '',
      images => \@base64_images,
    });

    print("\n\n\n".$answer."\n\n");

    my $end = time;
    printf("\n\n%u\n\n", $end - $start);
  }
}

exit 0;