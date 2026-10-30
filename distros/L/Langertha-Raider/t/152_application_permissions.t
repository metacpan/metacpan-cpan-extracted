#!/usr/bin/env perl
# ABSTRACT: The application's permission policy: its sources, the gate, events, the journal, config explain (ADR 0021, k154)
use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
my $home = path( isolate_home() );
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Config;

clear_engine_env();

my $json = JSON::MaybeXS->new( utf8 => 1 );

sub project {
  my ( %file ) = @_;
  my $root = Path::Tiny->tempdir;
  $root->child($_)->touchpath->spew_utf8( $file{$_} ) for keys %file;
  return $root;
}

sub home_config {
  my ( $content ) = @_;
  my $f = $home->child('.raider/config.yml');
  defined $content ? $f->touchpath->spew_utf8($content) : $f->remove;
  return;
}

subtest 'Config->permissions: both files, with sources' => sub {
  home_config("permissions:\n  deny: [ 'Bash(rm:*)' ]\n  default_mode: plan\n");
  my $root = project( '.raider/config.yml' => "permissions:\n  allow: 'Bash(make)'\n  ask: [ WebFetch ]\n"
    ."  default_mode: acceptEdits\n  additional_directories: [ ../docs ]\n" );
  my $p = Langertha::Raider::Config->new( root => "$root" )->permissions;
  is $p, {
    allow => [ { rule => 'Bash(make)', source => '.raider/config.yml' } ],
    ask   => [ { rule => 'WebFetch',   source => '.raider/config.yml' } ],
    deny  => [ { rule => 'Bash(rm:*)', source => '~/.raider/config.yml' } ],
    default_mode           => { value => 'acceptEdits', source => '.raider/config.yml' },
    additional_directories => [ { path => '../docs', source => '.raider/config.yml' } ],
  }, 'concatenated, a single string is a list, the project mode wins';
  home_config(undef);

  for my $bad (
    [ "permissions: [ Bash ]\n",                     qr/permissions: must be a mapping/ ],
    [ "permissions:\n  defaultMode: plan\n",         qr/permissions\.defaultMode: unknown key \(use default_mode\)/ ],
    [ "permissions:\n  allow: { a: 1 }\n",           qr/permissions\.allow: must be a list of strings/ ],
    [ "permissions:\n  deny: [ [ x ] ]\n",           qr/permissions\.deny: must be a list of strings/ ],
    [ "permissions:\n  default_mode: [ plan ]\n",    qr/default_mode: must be a mode name/ ],
  ) {
    my $dir = project( '.raider/config.yml' => $bad->[0] );
    my $c = Langertha::Raider::Config->new( root => "$dir" );
    like dies { $c->permissions }, $bad->[1], 'croaks: '.$bad->[0] =~ s/\n/ /gr;
  }

  my $sec = project( '.raider/config.yml' => "openai:\n  permissions: { allow: [ Bash ] }\n" );
  my $c = Langertha::Raider::Config->new( root => "$sec" );
  is $c->permissions->{allow}, [], 'a permissions: inside a section is not read';
  like $c->explain('openai')->{ignored}, [ { key => 'openai.permissions', reason => qr/top level/ } ], '... and reported';
};

subtest 'the mode: flag > config > settings > default' => sub {
  my $root = project(
    'CLAUDE.md'             => "# x\n",
    '.claude/settings.json' => '{ "permissions": { "defaultMode": "plan", "allow": [ "Bash" ] } }',
  );
  my $app = sub { Langertha::Raider::CLI->new( root => "$root", engine => 'openai', api_key => 'x', @_ ) };
  is [ map { $app->()->permissions->$_ } qw( mode mode_source ) ], [ 'plan', '.claude/settings.json' ], 'settings';
  is [ map { $app->( permission_mode => 'acceptEdits' )->permissions->$_ } qw( mode mode_source ) ],
    [ 'acceptEdits', '--permission-mode' ], 'the flag';
  is [ map { $app->( skip_permissions => 1 )->permissions->$_ } qw( mode mode_source ) ],
    [ 'bypassPermissions', '--dangerously-skip-permissions' ], 'skip';
  is $app->()->permissions->report->{rules}{allow}, [ { rule => 'Bash', source => '.claude/settings.json' } ],
    'settings rules in the Claude layout';

  my $native = project( '.raider/config.yml' => "permissions:\n  default_mode: nonsense\n" );
  my $p = Langertha::Raider::CLI->new( root => "$native", engine => 'openai', api_key => 'x' )->permissions;
  is $p->mode, 'default', 'an invalid mode from a file is skipped';
  like $p->ignored_modes, [ { value => 'nonsense', source => '.raider/config.yml', reason => qr/not a permission mode/ } ],
    '... and reported';

  like dies { $app->( permission_mode => 'yolo' ) }, qr/Unknown permission mode yolo/, 'an unknown mode croaks';
  like dies { $app->( permission_mode => 'plan', skip_permissions => 1 ) }, qr/only one of them/, 'not both';
};

subtest 'the gate in a run: refused with a reason, events, journal' => sub {
  my $root = project( 'keep.txt' => 'keep' );
  my @events;
  my $app = mock_app(
    root            => "$root",
    permission_mode => 'default',
    on_event        => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script          => [ { tool_calls => [ [ bash => { command => 'rm keep.txt' } ] ] }, { text => 'ok' } ],
  );
  my $session = $app->create_session;
  my $end = $app->run_prompt( 'go', session => $session );
  is $end->{status}, 'completed', 'the run completes';
  ok $root->child('keep.txt')->exists, 'bash did not run';
  my $text = $app->mock_engine->results->[0]{result}{content}[0]{text};
  like $text, qr/\APermission to use bash with command rm keep\.txt has been denied\. Reason: default mode asks before this call: bash runs code; nobody can approve it in this run\. To allow it, add a rule such as 'Bash\(rm keep\.txt\)' to \.raider\/config\.yml \(permissions: allow:\), or run raider with --permission-mode bypassPermissions\. Do not retry the same call/,
    'the model is told why and how to allow it';
  my ($denied) = grep { $_->{type} eq 'permission.denied' } @events;
  like $denied, { tool => 'bash', tool_source => qr/\Aengine:/, mode => 'default', by => 'noninteractive',
    source => 'permission_mode', reason => qr/nobody can approve it/ }, 'permission.denied';
  my @journal = map { $json->decode($_) } $session->path->lines_raw( { chomp => 1 } );
  like [ grep { $_->{type} =~ /\Apermission\./ } @journal ],
    [ { type => 'permission.denied', run => 'r1', tool => 'bash', by => 'noninteractive' } ],
    'the session journal records it';

  @events = ();
  is $app->set_permission_mode( 'acceptEdits', '/permissions' ), 'default', 'set_permission_mode returns the old mode';
  like \@events, [ { type => 'permission.mode', from => 'default', to => 'acceptEdits', why => '/permissions' } ],
    'permission.mode';
  is $app->permissions->mode, 'acceptEdits', 'the policy follows';
  like dies { $app->set_permission_mode('nope') }, qr/unknown permission mode/, 'an unknown mode croaks';
};

subtest 'config explain' => sub {
  my $root = project( '.raider/config.yml' => "permissions:\n  allow: [ Bash, 'Edit(src/**)', Frob ]\n"
    ."  deny: [ 'Read(./.env)' ]\n  default_mode: acceptEdits\n  additional_directories: [ ../docs ]\n" );
  my $report = Langertha::Raider::CLI->new( root => "$root", engine => 'openai', api_key => 'x' )->explain_config;
  like $report->{permissions}, {
    mode          => 'acceptEdits',
    mode_source   => '.raider/config.yml',
    rules         => { allow => [ { rule => 'Bash' }, { rule => 'Edit(src/**)' } ], deny => [ { rule => 'Read(./.env)' } ], ask => [] },
    invalid_rules => [ { rule => 'Frob', kind => 'allow', source => '.raider/config.yml', error => qr/unknown tool/ } ],
    additional_directories => [ { path => $root->parent->child('docs')->stringify, source => '.raider/config.yml' } ],
  }, 'the report';
  my $buf = '';
  open my $fh, '>', \$buf or die $!;
  Langertha::Raider::CLI::Output->new( out => $fh, color => 0 )->permissions_report( $report->{permissions} );
  like $buf, qr/^permissions: mode acceptEdits \(from \.raider\/config\.yml\)$/m, 'mode line';
  like $buf, qr/^  deny   1  \(\.raider\/config\.yml 1\)$/m, 'counts per kind and source';
  like $buf, qr/^  allow  2  /m, 'allow count';
  like $buf, qr/ignored allow rule Frob \(\.raider\/config\.yml\): unknown tool 'Frob'/, 'the invalid rule';
  like $buf, qr/additional directory .*docs \(\.raider\/config\.yml\)/, 'the directory';
};

subtest 'config explain: defaultMode auto of the Claude settings' => sub {
  my $root = project( '.claude/settings.json' => '{ "permissions": { "defaultMode": "auto" } }' );
  my $report = Langertha::Raider::CLI->new( root => "$root", engine => 'openai', api_key => 'x' )->explain_config;
  like $report->{permissions}, {
    mode => 'auto', mode_source => qr/settings\.json/,
    mode_note => 'claude auto -> raider acceptEdits + read-only bash allowlist', ignored_modes => [],
  }, 'the report maps it';
  my $buf = '';
  open my $fh, '>', \$buf or die $!;
  Langertha::Raider::CLI::Output->new( out => $fh, color => 0 )->permissions_report( $report->{permissions} );
  like $buf, qr/^permissions: mode auto \(from .*settings\.json\)$/m, 'mode line with the source';
  like $buf, qr/^  claude auto -> raider acceptEdits \+ read-only bash allowlist$/m, 'and the mapping';
};

subtest 'command line flags' => sub {
  my $err = '';
  open my $efh, '>', \$err or die $!;
  my $main = Langertha::Raider::CLI::Main->new( err => $efh );
  my ( $opt ) = $main->parse_options( '--permission-mode', 'plan', 'hi' );
  my %args = $main->app_args($opt);
  is $args{permission_mode}, 'plan', '--permission-mode reaches the application';
  ( $opt ) = $main->parse_options( '--dangerously-skip-permissions', 'hi' );
  is { $main->app_args($opt) }->{skip_permissions}, 1, '--dangerously-skip-permissions too';
  is [ $main->parse_options( '--permission-mode', 'yolo', 'hi' ) ], [], 'an unknown mode is a usage error';
  like $err, qr/--permission-mode: unknown mode 'yolo' \(one of default, acceptEdits, auto, plan, bypassPermissions\)/, '... saying so';
  is [ $main->parse_options( '--permission-mode', 'plan', '--dangerously-skip-permissions' ) ], [], 'both: usage error';
  like $main->usage, qr/--permission-mode MODE/, 'usage names --permission-mode';
  like $main->usage, qr/--dangerously-skip-permissions/, 'and --dangerously-skip-permissions';
};

done_testing;
