#!/usr/bin/env perl
# ABSTRACT: The metrics of a run carry the token ledger; every model call is a journalled model.usage (ADR 0026, addendum)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Path::Tiny;
use Test::Raider::MockAI qw( mock_app );

my $root = Path::Tiny->tempdir;
my @events;
my $app = mock_app(
  root     => "$root",
  script   => [
    { text => 'One.', usage => { prompt_tokens => 10, completion_tokens => 2 } },
    { text => 'Two.', usage => { prompt_tokens => 25, completion_tokens => 3 } },
  ],
  on_event => sub { my ( $t, %p ) = @_; push @events, { type => $t, %p } },
);

my $one = $app->run_prompt('first');
is $one->{metrics}{usage}{input_tokens}, 10, 'the first run: its tokens';
is $one->{metrics}{raids}, 1, 'the raider metrics are still there';

my $two = $app->run_prompt('second');
is $two->{metrics}{usage}, hash {
  field input_tokens => 35; field output_tokens => 5; field calls => 2;
  field models => hash { field virtual => hash { field input_tokens => 35; field calls => 2; etc }; end };
  etc;
}, 'cumulative, like the raider\'s metrics, with models';

my @usage = grep { $_->{type} eq 'model.usage' } @events;
is scalar @usage, 2, 'one model.usage per model call';
is [ map { $_->{purpose} } @usage ], [ 'chat', 'chat' ], 'purpose chat';
ok $app->is_journal_type('model.usage'), 'journalled';

done_testing;
