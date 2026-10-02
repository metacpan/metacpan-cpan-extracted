#!/usr/bin/env perl
# ABSTRACT: Live image generation tests

use strict;
use warnings;

use Test2::Bundle::More;

plan skip_all => 'Set TEST_LANGERTHA_OPENAI_API_KEY to run this test'
  unless $ENV{TEST_LANGERTHA_OPENAI_API_KEY};

use Langertha::Engine::OpenAI;
use Langertha::ImageGen;

my $engine = Langertha::Engine::OpenAI->new(
  api_key => $ENV{TEST_LANGERTHA_OPENAI_API_KEY},
);

subtest 'OpenAI image generation via engine' => sub {
  my $images = $engine->simple_image('A small red circle on a white background');
  ok($images, 'got result');
  ok(ref $images eq 'ARRAY', 'result is array');
  ok(scalar @$images >= 1, 'at least one image');

  my $img = $images->[0];
  ok($img->{url} || $img->{b64_json}, 'image has url or b64_json');
  diag "Image URL: $img->{url}" if $img->{url};
};

subtest 'ImageGen wrapper with model override' => sub {
  my $ig = Langertha::ImageGen->new(
    engine => $engine,
    model  => 'gpt-image-2.5-flare',
    size   => '1024x1024',
  );

  my $images = $ig->simple_image('A tiny blue square');
  ok($images, 'got result');
  ok(ref $images eq 'ARRAY', 'result is array');

  my $img = $images->[0];
  ok($img->{url} || $img->{b64_json}, 'image has url or b64_json');
  ok($img->{revised_prompt}, 'revised_prompt returned') if $img->{revised_prompt};
  diag "Revised prompt: $img->{revised_prompt}" if $img->{revised_prompt};
};

subtest 'ImageGen with Langfuse plugin' => sub {
  require Langertha::Plugin::Langfuse;

  my $lf = Langertha::Plugin::Langfuse->new(
    host       => Langertha::ImageGen->new(engine => $engine),
    public_key => $ENV{LANGFUSE_PUBLIC_KEY} // 'pk-test-disabled',
    secret_key => $ENV{LANGFUSE_SECRET_KEY} // 'sk-test-disabled',
  );

  my $ig = Langertha::ImageGen->new(
    engine  => $engine,
    plugins => [$lf],
  );

  my $images = $ig->simple_image('A green triangle');
  ok($images, 'got result with Langfuse plugin');
  ok(scalar @{$lf->_batch} > 0 || !$lf->enabled, 'Langfuse events created (or disabled)');
};

done_testing;
