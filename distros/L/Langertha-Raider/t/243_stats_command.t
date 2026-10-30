#!/usr/bin/env perl
# ABSTRACT: /stats shows the token ledger per model, with or without the trace (ADR 0026, addendum)
use strict;
use warnings;
use utf8;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY )};

my $app = Langertha::Raider::CLI->new(
  root => tempdir( CLEANUP => 1 ), engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0,
);
my $buf = '';
open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
my $cmds = Langertha::Raider::CLI::Commands->new(
  app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
);
my $read = sub { $fh->flush; my $t = $buf; $buf = ''; seek $fh, 0, 0; $t };

subtest 'before any model call' => sub {
  $cmds->dispatch('/stats');
  is $read->(), "no model calls yet.\n", 'says so';
};

subtest 'a total line and one line per model' => sub {
  $app->note_usage( model => 'claude-haiku-4-5', input_tokens => 1000, output_tokens => 20, cache_read_tokens => 800 );
  $app->note_usage( model => 'claude-haiku-4-5', input_tokens => 500,  output_tokens => 10, cache_write_tokens => 50 );
  $app->note_usage( model => 'web-model', input_tokens => 40, output_tokens => 4 );
  $cmds->dispatch('/stats');
  is $read->(),
    "total: 1540 in / 34 out (cache 800 read, 50 written) | 3 calls\n"
    ."  claude-haiku-4-5: 1500 in / 30 out (cache 800 read, 50 written) | 2 calls\n"
    ."  web-model: 40 in / 4 out (cache 0 read, 0 written) | 1 calls\n",
    'total first, models sorted';
};

subtest '/clear forgets the history, not the spent tokens' => sub {
  $cmds->dispatch('/clear');
  $read->();
  $cmds->dispatch('/stats');
  like $read->(), qr/\Atotal: 1540 in /, 'still counted';
};

done_testing;
