#!/usr/bin/env perl
# ABSTRACT: The how-to-use-raider doc lists the mounted tool set, not a table of its own (ADR 0005, k99)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use MCP::Server;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI;
use Langertha::Raider::Skill;

clear_engine_env();
delete @ENV{ grep { /^RAIDER_HALL_|^RAIDER_PACK_DIRS$/ } keys %ENV };

# A CLI that mounts one more tool server than the stock set.
{
  package Test::Raider::ProbeCLI;
  use Moose;
  extends 'Langertha::Raider::CLI';
  around _build_tool_servers => sub {
    my ( $orig, $self ) = @_;
    my $probe = MCP::Server->new(name => 'probe', version => '1.0');
    $probe->tool(
      name         => 'zz_probe',
      description  => 'Probe a | pipe. Second sentence stays out.',
      input_schema => { type => 'object', properties => { a => {} }, required => ['a'] },
      code         => sub { $_[0]->text_result('ok') },
    );
    return [ @{ $self->$orig }, $probe ];
  };
  __PACKAGE__->meta->make_immutable;
}

sub app {
  my ( %args ) = @_;
  my $class = delete $args{class} // 'Langertha::Raider::CLI';
  return $class->new(
    root    => tempdir(CLEANUP => 1),
    engine  => 'openai',
    api_key => 'test',
    model   => 'gpt-4o-mini',
    trace   => 0,
    detect  => 0,
    %args,
  );
}

# The rows of the doc's tool table as [ signature, purpose ].
sub rows {
  my ( $app ) = @_;
  my ($table) = Langertha::Raider::Skill->new(app => $app)->markdown
    =~ /^## Tools the agent has\n\n((?:\|.*\n)+)/m or return [];
  my @lines = split /\n/, $table;
  splice @lines, 0, 2;   # header, rule
  return [ map { [ /^\| `(.*?)`\s+\| (.*?)\s+\|$/ ] } @lines ];
}

# The tool lines of the prompt's tool description.
sub prompt_signatures {
  my ( $app ) = @_;
  my ($block) = $app->mission =~ /^Tools \(MCP\):\n((?:  - .*\n)+)/m or return [];
  return [ map { s/^  - //r } split /\n/, $block ];
}

subtest 'stock set: the table is the prompt tool set' => sub {
  my $app = app();
  my $rows = rows($app);
  is([ map { $_->[0] } @$rows ], prompt_signatures($app), 'same tools, same signatures, same order');
  is($rows->[4], [ 'bash(command, [compress], [timeout], [working_directory])',
    'Run a shell command with bash -c' ], 'bash row from its schema and description');
  ok(!(grep { $_->[0] =~ /^perl_/ } @$rows), 'Perl tools not mounted, not documented');
};

subtest 'Perl tools documented once mounted' => sub {
  my $rows = rows(app(perl => 1));
  ok((grep { $_->[0] eq 'perl_eval(code, [stdin], [timeout])' } @$rows), 'perl_eval');
  ok((grep { $_->[0] =~ /^perl_check\(/ } @$rows), 'perl_check');
  ok((grep { $_->[0] =~ /^perl_cpanm\(/ } @$rows), 'perl_cpanm');
};

subtest 'an additionally mounted tool shows up' => sub {
  my $rows = rows(app(class => 'Test::Raider::ProbeCLI'));
  is($rows->[-1], [ 'zz_probe(a)', 'Probe a \| pipe' ],
    'first sentence of the description, pipe escaped for the table');
};

subtest 'plain Markdown, no POD format codes (k104)' => sub {
  my $skill = Langertha::Raider::Skill->new(app => app(perl => 1));
  for my $variant (qw( markdown claude_skill )) {
    my @pod = $skill->$variant =~ /\b([BCEFILSXZ]<[^>\n]*>)/g;
    is(\@pod, [], $variant.' carries no POD markup');
  }
  like($skill->markdown, qr/wraps `Langertha::Raider` with/, 'module name as a code span');
};

done_testing;
