#!/usr/bin/env perl
# ABSTRACT: The permission policy: modes, rule order, session rules, revision, sub-runs (ADR 0021, k154)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::Permissions;
use Langertha::Raider::Permissions::Rule;

# Pure logic: Langertha::Raider::Permissions->decide on canonical calls. No
# raid, no application.

my $class = 'Langertha::Raider::Permissions';
my $tmp   = Path::Tiny->tempdir;
my $root  = $tmp->child('proj');
my $home  = $tmp->child('home');
my $docs  = $tmp->child('docs');
$_->mkpath for $root, $home, $docs;

sub policy {
  my ( %arg ) = @_;
  return $class->new( root => $root->stringify, home => $home->stringify, %arg );
}
sub tc   { { name => $_[0], source => $_[2] // 'engine:1', arguments => $_[1] // {} } }
sub bash { tc( bash => { command => $_[0] } ) }
sub rules {
  my ( %kind ) = @_;
  return { map { my $k = $_; $k => [ map { { rule => $_, source => 'src-'.$k } } @{ $kind{$k} } ] } keys %kind };
}
sub verdict { $_[0]->decide( $_[1] )->{verdict} }

subtest 'modes' => sub {
  is [ $class->modes ], [qw( default acceptEdits auto plan bypassPermissions )], 'the modes';
  ok $class->is_mode('acceptEdits'), 'is_mode';
  ok !$class->is_mode('acceptedits'), 'case matters';
  ok !$class->is_mode(undef), 'undef is no mode';
  like dies { policy( mode => 'yolo' ) }, qr/unknown permission mode yolo/, 'constructor croaks';
  my $p = policy();
  like dies { $p->set_mode('nope') }, qr/unknown permission mode/, 'set_mode croaks';
  is $p->set_mode( 'plan', '/permissions' ), 'default', 'set_mode returns the previous mode';
  is [ $p->mode, $p->mode_source ], [ 'plan', '/permissions' ], 'mode and source';
};

subtest 'default mode without rules' => sub {
  my $p = policy();
  is verdict( $p, tc( read_file => { path => 'x' } ) ), 'allow', 'reading';
  is verdict( $p, tc( grep => { pattern => 'x' } ) ), 'allow', 'grep';
  is verdict( $p, tc('todo_write') ), 'allow', 'todo_write (no effects)';
  is verdict( $p, tc('raider_pause', {}, 'raider') ), 'allow', 'empty effect list';
  is verdict( $p, tc('ask_user') ), 'allow', 'ask_user although message';
  is verdict( $p, tc('raider_ask_user', {}, 'raider') ), 'allow', 'raider_ask_user';
  is verdict( $p, tc('skill') ), 'allow', 'skill';
  is verdict( $p, tc('exit_plan_mode') ), 'allow', 'exit_plan_mode';
  for my $t (qw( write_file edit_file bash perl_eval web_fetch web_search telegram_reply hall_spawn )) {
    is verdict( $p, tc($t) ), 'ask', "$t asks";
  }
  my $v = $p->decide( bash('ls') );
  is $v, { verdict => 'ask', by => 'mode', source => 'default', mode => 'default',
    reason => 'default mode asks before this call: bash runs code' }, 'the verdict hash';
  is verdict( $p, tc('agent') ), 'allow', 'agent (no effects of its own; ADR 0020)';
  is verdict( $p, tc('frobnicate') ), 'ask', 'a tool without an effect entry asks';
  my $f = $p->decide( tc( 'read_file', {}, 'catalog:github' ) );
  is $f->{verdict}, 'ask', 'a foreign tool asks, even named read_file';
  like $f->{reason}, qr/not a tool of raider \(MCP server 'github'\)/, '... and says why';
  is verdict( policy( source_servers => { 'engine:7' => 'x' } ), tc( 'read_file', {}, 'engine:7' ) ),
    'ask', 'source_servers marks an engine source foreign';
  is verdict( $p, { name => 'read_file', arguments => {} } ), 'ask', 'no source at all: foreign';
  like dies { $p->decide('bash') }, qr/needs a call hash/, 'decide croaks on a non-hash';
};

subtest 'rule order: deny before ask before allow, across sources' => sub {
  my $p = policy( rules => rules(
    allow => [ 'Bash', 'Edit' ],
    ask   => [ 'Bash(git push:*)' ],
    deny  => [ 'Bash(rm:*)' ],
  ) );
  my $deny = $p->decide( bash('rm -rf x') );
  is [ @{$deny}{qw( verdict by rule source )} ], [ 'deny', 'rule', 'Bash(rm:*)', 'src-deny' ], 'deny wins';
  like $deny->{reason}, qr/denied by rule 'Bash\(rm:\*\)' from src-deny/, 'reason names rule and source';
  is verdict( $p, bash('git push origin') ), 'ask', 'ask before allow';
  is verdict( $p, bash('ls') ), 'allow', 'allow';
  is verdict( $p, tc( write_file => { path => 'a' } ) ), 'allow', 'Edit allows writing';

  my $two = policy( rules => {
    allow => [ { rule => 'Read', source => '.claude/settings.local.json' } ],
    deny  => [ { rule => 'Read(./.env)', source => '~/.claude/settings.json' } ],
  } );
  my $v = $two->decide( tc( read_file => { path => '.env' } ) );
  is [ @{$v}{qw( verdict source )} ], [ 'deny', '~/.claude/settings.json' ], 'a user deny beats a local allow';
};

subtest 'composite bash commands' => sub {
  my $p = policy( rules => rules( allow => [ 'Bash(npm test:*)', 'Bash(git status)' ] ) );
  my $v = $p->decide( bash('npm test && git status') );
  is $v->{verdict}, 'allow', 'every part covered by some allow rule';
  is $v->{rule}, 'Bash(npm test:*), Bash(git status)', 'both rules named';
  is verdict( $p, bash('npm test && rm x') ), 'ask', 'a part without a rule falls back to the mode';
  is verdict( $p, bash('npm test && git status > out') ), 'ask', 'a redirection into a file is never covered';
  is verdict( $p, bash('npm test $(git status)') ), 'ask', 'nor a substitution';
  is verdict( policy( mode => 'bypassPermissions', rules => rules( deny => ['Bash(rm:*)'] ) ),
    bash('ls && rm x') ), 'deny', 'the && trick does not escape a deny rule';
};

subtest 'invalid rules are ignored and reported' => sub {
  my $p = policy( rules => rules( allow => [ 'Frobnicate', 'Bash(' ], deny => [ 'WebFetch(x.com)' ] ) );
  is [ map { $_->text } $p->invalid_rules ], [ 'WebFetch(x.com)', 'Frobnicate', 'Bash(' ], 'reported';
  is [ $p->rule_list ], [], 'not in the rule list';
  is verdict( $p, bash('ls') ), 'ask', 'an invalid allow rule widens nothing';
  my $q = policy( rules => { allow => [ 'Bash', { rule => undef } ] } );
  is [ map { [ $_->text, $_->source ] } $q->rule_list ], [ [ 'Bash', 'unknown' ] ], 'plain strings get source unknown';
};

subtest 'acceptEdits' => sub {
  my $p = policy( mode => 'acceptEdits',
    additional_directories => [ { path => '../docs', source => 'x' } ] );
  is verdict( $p, tc( write_file => { path => 'lib/A.pm' } ) ), 'allow', 'inside the root';
  is verdict( $p, tc( edit_file  => { path => $docs->child('a.md')->stringify } ) ), 'allow', 'inside an additional directory';
  is verdict( $p, tc( write_file => { path => '../elsewhere/x' } ) ), 'ask', 'outside asks';
  is verdict( $p, tc( write_file => { path => 'lib/../../elsewhere' } ) ), 'ask', '.. cannot sneak out';
  is verdict( $p, bash('ls') ), 'ask', 'bash still asks';
  is verdict( $p, tc('web_fetch', { url => 'http://x' }) ), 'ask', 'network still asks';
  is [ $p->allowed_roots ], [ $root->stringify, $docs->stringify ], 'allowed_roots';
  is [ policy( additional_directories => [ { path => '~/notes' }, '/abs/x' ] )->additional_directory_paths ],
    [ $home->child('notes')->stringify, '/abs/x' ], 'home and absolute directories';
};

subtest 'plan mode' => sub {
  my $p = policy( mode => 'plan', rules => rules( allow => [ 'Edit', 'Bash' ] ) );
  my $v = $p->decide( tc( write_file => { path => 'a' } ) );
  is [ @{$v}{qw( verdict by )} ], [ 'deny', 'mode' ], 'writing is refused, allow rule or not';
  like $v->{reason}, qr/\Aplan mode: write_file changes files.*present your plan with exit_plan_mode first/,
    'the reason points at exit_plan_mode';
  is verdict( $p, bash('ls') ), 'deny', 'bash is refused';
  is verdict( $p, tc('telegram_reply') ), 'deny', 'messages are refused';
  is verdict( $p, tc( read_file => { path => 'a' } ) ), 'allow', 'reading is fine';
  is verdict( $p, tc('ask_user') ), 'allow', 'ask_user is fine';
  is verdict( $p, tc('exit_plan_mode') ), 'allow', 'exit_plan_mode is fine';
  is verdict( $p, tc('todo_write') ), 'allow', 'todo_write is fine';
  is verdict( $p, tc('web_fetch') ), 'ask', 'network asks as in default';
  is verdict( $p, tc( 'x', {}, 'catalog:y' ) ), 'ask', 'a foreign tool asks';
};

subtest 'bypassPermissions' => sub {
  my $p = policy( mode => 'bypassPermissions',
    rules => rules( deny => ['Read(./.env)'], ask => ['Bash'] ) );
  is verdict( $p, bash('rm -rf x') ), 'allow', 'ask rules do not ask';
  is verdict( $p, tc( 'x', {}, 'catalog:y' ) ), 'allow', 'foreign tools run';
  is verdict( $p, tc( read_file => { path => '.env' } ) ), 'deny', 'deny rules still hold';
};

subtest 'session rules, revision and sub-runs' => sub {
  my $p = policy( rules => rules( deny => ['Bash(rm:*)'] ) );
  my $rev0 = $p->policy_revision;
  like $rev0, qr/\A[0-9a-f]{64}\z/, 'revision is a sha256';
  is $p->policy_revision, $rev0, 'stable';

  my $sub = $p->for_subrun;
  isa_ok $sub, $class;
  is $sub->policy_revision, $rev0, 'a sub-run starts under the same policy';

  is verdict( $p, bash('make test') ), 'ask', 'before the session rule';
  my $rule = $p->add_session_rule('Bash(make test)');
  isa_ok $rule, 'Langertha::Raider::Permissions::Rule';
  is [ $rule->source, $rule->kind ], [ 'session', 'allow' ], 'source session, kind allow';
  is $p->add_session_rule('Bash(make test)'), $rule, 'adding the same text again changes nothing';
  is scalar @{ $p->session_rules }, 1, 'one session rule';
  is verdict( $p, bash('make test') ), 'allow', 'allowed for the session';
  is verdict( $sub, bash('make test') ), 'allow', 'the sub-run shares session rules';
  isnt $p->policy_revision, $rev0, 'a session rule changes the revision';
  is $sub->policy_revision, $p->policy_revision, 'in both';

  $sub->add_session_rule('WebFetch(domain:perl.org)');
  is verdict( $p, tc( web_fetch => { url => 'https://perl.org/' } ) ), 'allow', 'and the other way round';

  is verdict( $p, bash('rm x') ), 'deny', 'a session rule never beats a deny rule';
  like dies { $p->add_session_rule('Frob') }, qr/unknown tool/, 'an invalid session rule croaks';

  my $rev = $p->policy_revision;
  $sub->set_mode('plan');
  is [ $p->mode, $sub->mode ], [ 'default', 'plan' ], 'a sub-run mode change stays there';
  is $p->policy_revision, $rev, 'and leaves the parent revision';
  $p->set_mode('acceptEdits');
  isnt $p->policy_revision, $rev, 'a mode change changes the revision';
  is $p->for_subrun->mode, 'acceptEdits', 'a new sub-run takes the current mode';
};

subtest 'suggest_rule' => sub {
  my $p = policy();
  my %want = (
    'Bash(npm run test -- x)'         => bash('  npm run test -- x '),
    'Bash(make && make test)'         => bash('make && make test'),
    'Edit(lib/Foo/**)'                => tc( write_file => { path => 'lib/Foo/Bar.pm' } ),
    'Edit(/**)'                       => tc( edit_file  => { path => 'README' } ),
    'Edit(/'.$docs.'/**)'             => tc( write_file => { path => $docs->child('x.md')->stringify } ),
    'WebFetch(domain:www.perl.org)'   => tc( web_fetch  => { url => 'https://WWW.perl.org/x' } ),
    'mcp__github__create_issue'       => tc( 'create_issue', {}, 'catalog:github' ),
    'TodoWrite'                       => tc('todo_write'),
    'perl_eval'                       => tc('perl_eval'),
  );
  for my $text ( sort keys %want ) {
    my $call = $want{$text};
    is $p->suggest_rule($call), $text, "suggests $text";
    my $q = policy();
    $q->add_session_rule($text);
    is verdict( $q, $call ), 'allow', '... and the rule allows the call';
  }
  is $p->suggest_rule( bash('echo $(date)') ), undef, 'no rule for a substitution';
  is $p->suggest_rule( bash('ls > out') ), undef, 'no rule for a redirection';
  is $p->suggest_rule( { name => 'x', arguments => {} } ), undef, 'no rule for a tool without a server';
};

done_testing;
