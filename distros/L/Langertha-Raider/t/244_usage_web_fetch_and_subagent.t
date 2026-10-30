#!/usr/bin/env perl
# ABSTRACT: A tool's own model call (web_fetch prompt) and a subagent's calls reach the ledger exactly once (ADR 0026, addendum)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; require Langertha::Virtual::Rules; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Env qw( isolate_home );
isolate_home();
use IO::Async::Loop;
use Path::Tiny;
use Langertha::Raider::Application;
use Test::Raider::MockAI qw( mock_app );

my $root = Path::Tiny->tempdir;

subtest 'web_fetch: counted once, with the cache counts, and still an event' => sub {
  my @events;
  my $app = mock_app( root => "$root",
    on_event => sub { my ( $t, %p ) = @_; push @events, { type => $t, %p } } );
  my $virtual = Langertha::Engine::Virtual->new( langfuse_enabled => 0, script => [
    Langertha::Virtual::Rules::answer( 'Yes.', usage => {
      prompt_tokens => 50, completion_tokens => 4, prompt_tokens_details => { cached_tokens => 30 } } ),
  ] );
  Langertha::Raider::Application->meta->get_attribute('web_fetch_engine')->set_value( $app, $virtual );
  my $loop = IO::Async::Loop->new;
  is $loop->await( $app->_web_fetch_answer_f('page and question') )->get, 'Yes.', 'the answer';
  my $u = $app->usage_stats;
  is [ @$u{qw( input_tokens output_tokens cache_read_tokens calls )} ], [ 50, 4, 30, 1 ], 'once in the ledger';
  is scalar( grep { $_->{type} eq 'model.usage' && $_->{purpose} eq 'web_fetch' } @events ), 1, 'one event';
};

subtest 'a main run and its subagent: every call, once' => sub {
  $root->child('.raider/agents')->mkpath;
  $root->child('.raider/agents/helper.md')->spew_utf8("---\ndescription: Helps.\ntools: Bash\n---\nBODY\n");
  my $app = mock_app( root => "$root", permission_mode => 'bypassPermissions', script => [
    { tool_calls => [ [ agent => { description => 'Help', prompt => 'Go.', subagent_type => 'helper' } ] ],
      usage => { prompt_tokens => 100, completion_tokens => 10 } },
    { text => 'sub done', usage => { prompt_tokens => 30, completion_tokens => 6 } },
    { text => 'all done', usage => { prompt_tokens => 140, completion_tokens => 7 } },
  ] );
  my $out = $app->run_prompt('go');
  is $out->{status}, 'completed', 'completed' or diag $out->{error};
  is $out->{metrics}{usage}{calls}, 3, 'three model calls: main, subagent, main';
  is $out->{metrics}{usage}{input_tokens}, 270, 'summed';
};

done_testing;
