#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Ollama;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

plan(6);

my $ollama_testurl = 'http://test.url:12345';
my $ollama = Langertha::Engine::Ollama->new(
  url => $ollama_testurl,
  model => 'model',
  system_prompt => 'systemprompt',
);
my $ollama_tags_request = $ollama->tags;
is($ollama_tags_request->uri, $ollama_testurl.'/api/tags', 'Ollama tags request uri is correct');
is($ollama_tags_request->method, 'GET', 'Ollama tags request method is correct');
is($ollama_tags_request->header('Content-Type'), 'application/json; charset=utf-8', 'Ollama tags request JSON Content Type is set');

my $ollama_ps_request = $ollama->ps;
is($ollama_ps_request->uri, $ollama_testurl.'/api/ps', 'Ollama ps request uri is correct');
is($ollama_ps_request->method, 'GET', 'Ollama ps request method is correct');
is($ollama_ps_request->header('Content-Type'), 'application/json; charset=utf-8', 'Ollama ps request JSON Content Type is set');

done_testing;
