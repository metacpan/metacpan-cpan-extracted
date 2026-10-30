#!/usr/bin/env perl
# ABSTRACT: The auto permission mode (Claude Code defaultMode "auto"): acceptEdits + a read-only bash allowlist (ADR 0021 Nachtrag P2, k158)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::Permissions;
use Langertha::Raider::Permissions::ReadOnlyBash;

my $ro    = 'Langertha::Raider::Permissions::ReadOnlyBash';
my $class = 'Langertha::Raider::Permissions';
my $tmp   = Path::Tiny->tempdir;
my $root  = $tmp->child('proj');
my $home  = $tmp->child('home');
$_->mkpath for $root, $home;

sub policy { $class->new( root => "$root", home => "$home", @_ ) }
sub bash   { { name => 'bash', source => 'engine:1', arguments => { command => $_[0] } } }
sub verdict { $_[0]->decide( $_[1] )->{verdict} }

subtest 'allowlist: covered' => sub {
  ok $ro->covers($_), "covers: $_" for (
    'ls', 'ls -la src', 'pwd', 'git status', 'git status && ls', 'git diff HEAD~1 -- lib', 'git log --oneline -n 5',
    'git branch', 'git branch -a', 'git show HEAD:README.md', 'cat a.txt | head -n 3 | wc -l',
    'grep -rn "foo bar" lib', 'rg -n --glob "*.pm" Moose lib', "grep 'a|b' file", 'find . -name "*.pm" -type f',
    'echo hello', 'which perl', 'date +%Y-%m-%d', 'date -u', 'uname -a', 'cd lib && ls',
    'ls /nonexistent 2>/dev/null', 'git status 2>&1', 'sort -rn counts.txt', 'uniq file', 'jq .a data.json',
    "ls\npwd", 'git tag --list',
  );
};

subtest 'allowlist: not covered' => sub {
  ok !$ro->covers($_), "refused: $_" for (
    'git status; rm x', 'git status && rm -rf x', 'cat $(x)', 'cat `x`', 'ls > f', 'ls >> f', 'echo hi > /etc/x', 'ls &> out',
    'cat <(x)', "cat <<EOF\nx\nEOF", 'echo "unbalanced', 'rm x', 'make', 'sudo ls', 'env ls', 'FOO=1 ls', '/bin/ls', 'xargs ls',
    'bash -c ls', 'sh', 'perl -e 1', 'sed -n 1p x', 'awk 1 x', 'ls $HOME', 'ls "$HOME"', 'echo "a\\b"', 'ls ~/x; true && rm y',
    'find . -exec rm {} ;', 'find . -delete', 'find . -fprint out', 'find . -execdir sh ;', 'find . -ok rm {} ;',
    'rg --pre sh x', 'rg -z x', 'grep --pre=sh x', 'sort -o out in', 'sort --output=out in', 'sort --out=out in', 'sort -ro out in',
    'date -s 12:00', 'date 010100002030', 'date --set=x', 'uniq in out',
    'git push', 'git commit -m x', 'git checkout x', 'git branch -D x', 'git branch newname', 'git tag v1', 'git remote add a b',
    'git -c core.pager=sh log', 'git -C x status', 'git diff --output=f', 'git diff --out=f', 'git log --ext-diff', 'git show --textconv x',
    'git config user.name x', 'git', 'ls | sh', 'cat a | xargs rm',
  );
  ok !$ro->covers(''), 'empty';
  ok !$ro->covers(undef), 'undef';
};

subtest 'auto mode in the policy' => sub {
  my $p = policy( mode => 'auto' );
  is $p->mode, 'auto', 'mode name';
  is verdict( $p, bash('git status && ls') ), 'allow', 'read-only chain allowed';
  is $p->decide( bash('git status && ls') )->{reason}, 'auto mode, a read-only bash command', '... and why';
  is verdict( $p, bash('git status; rm x') ), 'ask', 'a rm in the chain asks';
  is verdict( $p, bash('cat $(x)') ), 'ask', 'substitution asks';
  is verdict( $p, bash('ls > f') ), 'ask', 'redirection into a file asks';
  like $p->decide( bash('make') )->{reason}, qr/\Aauto mode asks before this call: bash runs code/, 'asks name the mode';
  is verdict( $p, { name => 'write_file', source => 'engine:1', arguments => { path => 'a.txt', content => 'x' } } ), 'allow',
    'edits in the root allowed like acceptEdits';
  is verdict( $p, { name => 'write_file', source => 'engine:1', arguments => { path => '/etc/x', content => 'x' } } ), 'ask',
    'edits outside the root ask';
  is verdict( $p, { name => 'web_fetch', source => 'engine:1', arguments => { url => 'https://example.org' } } ), 'ask', 'network asks';
  is verdict( $p, { name => 'bash', source => 'catalog:foo', arguments => { command => 'ls' } } ), 'ask',
    'a foreign tool named bash is not raider bash';
  is verdict( policy( mode => 'acceptEdits' ), bash('ls') ), 'ask', 'acceptEdits itself still asks about bash';
};

subtest 'rules around auto' => sub {
  my $deny = policy( mode => 'auto', rules => { deny => [ { rule => 'Bash(git status:*)', source => 'x' } ] } );
  is verdict( $deny, bash('git status') ), 'deny', 'a deny rule beats the allowlist';
  my $ask = policy( mode => 'auto', rules => { ask => [ { rule => 'Bash(ls:*)', source => 'x' } ] } );
  is verdict( $ask, bash('ls -l') ), 'ask', 'an ask rule beats the allowlist';
  my $allow = policy( mode => 'auto', rules => { allow => [ { rule => 'Bash(make:*)', source => 'x' } ] } );
  is verdict( $allow, bash('make test') ), 'allow', "the person's allow rule still works";
  is verdict( $allow, bash('make && rm x') ), 'ask', 'one part uncovered asks';
};

subtest 'revision, report, sources' => sub {
  my $a = policy( mode => 'auto' );
  my $b = policy( mode => 'acceptEdits' );
  isnt $a->policy_revision, $b->policy_revision, 'auto and acceptEdits differ in the revision';
  my $rev = $a->policy_revision;
  $a->set_mode('default');
  isnt $a->policy_revision, $rev, 'switching away changes it';
  $a->set_mode( 'auto', '/permissions' );
  is $a->policy_revision, $rev, 'and back';

  my $p = $class->from_sources(
    root => "$root", home => "$home",
    sources => [ { allow => [], ask => [], deny => [], additional_directories => [],
      default_mode => { value => 'auto', source => '.claude/settings.json' } } ],
  );
  is $p->mode, 'auto', 'defaultMode auto from the Claude settings';
  is $p->mode_source, '.claude/settings.json', '... with its source';
  is $p->ignored_modes, [], 'not ignored any more';
  is $p->report->{mode_note}, 'claude auto -> raider acceptEdits + read-only bash allowlist', 'config explain says how it maps';
  my $q = $class->from_sources(
    root => "$root", home => "$home",
    sources => [ { default_mode => { value => 'auto', source => '.raider/config.yml' } } ],
  );
  is $q->report->{mode_note}, 'auto -> acceptEdits + read-only bash allowlist', 'the raider config says it plainly';
  ok !exists policy( mode => 'plan' )->report->{mode_note}, 'no note in other modes';
  my $dont = $class->from_sources( root => "$root", home => "$home",
    sources => [ { default_mode => { value => 'dontAsk', source => '.claude/settings.json' } } ] );
  is $dont->mode, 'default', 'other unknown names are still skipped';
  is scalar @{ $dont->ignored_modes }, 1, '... and reported';
  my $cli = $class->from_sources( root => "$root", home => "$home",
    cli_mode => { value => 'auto', source => '--permission-mode' } );
  is $cli->mode, 'auto', '--permission-mode auto';
};

done_testing;
