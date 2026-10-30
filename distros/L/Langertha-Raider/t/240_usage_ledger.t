#!/usr/bin/env perl
# ABSTRACT: The application's token ledger: note_usage and usage_stats (ADR 0026, addendum)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Path::Tiny;
use Langertha::Raider::Application;

my $app = Langertha::Raider::Application->new( root => Path::Tiny->tempdir->stringify, engine => 'openai', api_key => 'test' );

subtest 'empty: zeros, no models' => sub {
  is $app->usage_stats, {
    input_tokens => 0, output_tokens => 0, cache_read_tokens => 0, cache_write_tokens => 0,
    calls => 0, models => {},
  }, 'nothing counted';
};

subtest 'calls add up, per model and in total' => sub {
  $app->note_usage( model => 'haiku', input_tokens => 100, output_tokens => 10, cache_read_tokens => 80 );
  $app->note_usage( model => 'haiku', input_tokens => 50,  output_tokens => 5,  cache_write_tokens => 20 );
  $app->note_usage( model => 'opus',  input_tokens => 7,   output_tokens => 3 );
  my $u = $app->usage_stats;
  is $u, hash {
    field input_tokens => 157; field output_tokens => 18;
    field cache_read_tokens => 80; field cache_write_tokens => 20; field calls => 3;
    field models => hash {
      field haiku => { input_tokens => 150, output_tokens => 15, cache_read_tokens => 80, cache_write_tokens => 20, calls => 2 };
      field opus  => { input_tokens => 7, output_tokens => 3, cache_read_tokens => 0, cache_write_tokens => 0, calls => 1 };
      end;
    };
    end;
  }, 'totals and per model';
};

subtest 'a call without a model is counted as unknown' => sub {
  $app->note_usage( input_tokens => 1, output_tokens => 1 );
  ok exists $app->usage_stats->{models}{unknown}, 'unknown';
  is $app->usage_stats->{models}{unknown}{calls}, 1, 'one call';
};

subtest 'usage_stats is a copy' => sub {
  my $u = $app->usage_stats;
  $u->{input_tokens} = 0;
  $u->{models}{haiku}{input_tokens} = 0;
  is $app->usage_stats->{models}{haiku}{input_tokens}, 150, 'the ledger is untouched';
};

done_testing;
