#!/usr/bin/env perl
# ABSTRACT: Permission rules in Claude Code syntax: parsing and matching (ADR 0021, k154)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::Permissions::Rule;

# Pure logic: a rule is parsed once, invalid rules never match, and every
# match is held against the canonical call the tool gate sees. No raid.

my $class = 'Langertha::Raider::Permissions::Rule';
my $tmp   = Path::Tiny->tempdir;
my $root  = $tmp->child('proj');
my $home  = $tmp->child('home');
$_->mkpath for $root, $home, $root->child('lib'), $root->child('secrets');
$root->child('secrets/key')->spew('k');
symlink $root->child('secrets')->stringify, $root->child('lib/link')->stringify
  or die "symlink: $!";
my $real_root = path( $root->realpath )->stringify;

my $ctx = {
  roots   => [ $root->stringify, ( $real_root ne $root->stringify ? $real_root : () ) ],
  homes   => [ $home->stringify ],
  builtin => 1,
};

sub rule { $class->new( text => $_[0], source => 'test', kind => $_[1] // 'deny' ) }
sub tc { { name => $_[0], source => 'engine:1', arguments => $_[1] // {} } }
sub bash { tc( bash => { command => $_[0] } ) }

subtest 'parsing' => sub {
  my $r = rule('Bash(npm run test:*)', 'allow');
  ok $r->is_valid, 'Bash with prefix';
  is $r->family, 'bash', 'family';
  is $r->tools, [qw( bash monitor )], 'Bash covers bash and monitor (a Monitor runs a command the same way)';
  is rule('Monitor(tail -f *)')->tools, ['monitor'], 'Monitor names the monitor alone';
  is $r->specifier, 'npm run test:*', 'specifier';

  is rule('Read')->tools, [qw( read_file list_files glob grep )], 'Read covers every reading tool';
  is rule('Edit(src/**)')->tools, [qw( write_file edit_file multi_edit )], "Edit covers every writing tool";
  is rule('Write')->tools, [qw( write_file edit_file multi_edit )], "Write as well";
  is rule('write_file')->tools, [qw( write_file edit_file multi_edit )], "raider name accepted";
  is rule('TodoWrite')->tools, ['todo_write'], 'Claude name through ToolNames';
  is rule('perl_eval')->tools, ['perl_eval'], 'raider-only tool by its name';

  my $mcp = rule('mcp__github__create_issue');
  ok $mcp->is_valid, 'mcp rule';
  is [ $mcp->mcp_server, $mcp->mcp_tool ], [ 'github', 'create_issue' ], 'server and tool';
  is [ rule('mcp__github')->mcp_server, rule('mcp__github')->mcp_tool ], [ 'github', undef ], 'whole server';
  is rule('mcp__github__*')->mcp_tool, undef, 'server wildcard';
  is rule('mcp__my_srv__do_it')->mcp_server, 'my_srv', 'server name with an underscore';

  for my $bad ( 'Frobnicate', 'Bash(', 'Bash()', 'TodoWrite(x)', 'Agent()', 'WebFetch(example.com)',
                'WebSearch(perl)', 'mcp__x(y)', '', '  ', 'Read(a) b' ) {
    my $r = rule($bad);
    ok !$r->is_valid, "invalid: '$bad'";
    ok length $r->error, '... with an error';
    ok !$r->matches( bash('ls'), $ctx ), '... never matches';
  }
  like dies { rule( 'Bash', 'grant' ) }, qr/kind must be/, 'unknown kind croaks';
  is rule('Bash(x)')->as_hash, { rule => 'Bash(x)', source => 'test', kind => 'deny' }, 'as_hash';
  ok exists rule('Nope')->as_hash->{error}, 'as_hash of an invalid rule has the error';
};

subtest 'bare tool rules' => sub {
  ok rule('Bash')->matches( bash('anything $(at all) > f'), $ctx ), 'Bash matches every command';
  ok rule( 'Bash', 'allow' )->matches( bash('a $(b) > f'), $ctx ), 'bare allow covers every command too';
  ok !rule('Bash')->matches( tc('read_file', { path => 'x' }), $ctx ), 'not another tool';
  ok rule('WebSearch')->matches( tc( 'web_search', { query => 'x' } ), $ctx ), 'WebSearch';
};

subtest 'bash: exact, prefix, glob' => sub {
  my $exact = rule( 'Bash(npm test)', 'allow' );
  ok $exact->matches( bash('npm test'), $ctx ), 'exact';
  ok $exact->matches( bash('  npm test  '), $ctx ), 'surrounding blanks do not matter';
  ok !$exact->matches( bash('npm test -- x'), $ctx ), 'exact is exact';

  my $prefix = rule( 'Bash(npm run test:*)', 'allow' );
  ok $prefix->matches( bash('npm run test'), $ctx ), 'prefix alone';
  ok $prefix->matches( bash('npm run test -- x'), $ctx ), 'prefix with arguments';
  ok !$prefix->matches( bash('npm run tests'), $ctx ), 'word boundary';
  ok !$prefix->matches( bash('xnpm run test'), $ctx ), 'anchored at the start';

  my $glob = rule( 'Bash(git * --dry-run)', 'allow' );
  ok $glob->matches( bash('git push --dry-run'), $ctx ), 'glob';
  ok $glob->matches( bash('git push origin main --dry-run'), $ctx ), 'glob spans words';
  ok !$glob->matches( bash('git push'), $ctx ), 'glob is anchored at the end';
};

subtest 'bash: composite commands are strict' => sub {
  my $allow = rule( 'Bash(npm test:*)', 'allow' );
  ok !$allow->matches( bash('npm test && rm -rf /'), $ctx ), '&& is not covered by one rule';
  ok !$allow->matches( bash('npm test; rm x'), $ctx ), ';';
  ok !$allow->matches( bash('npm test | sh'), $ctx ), '|';
  ok !$allow->matches( bash("npm test\nrm x"), $ctx ), 'newline';
  ok !$allow->matches( bash('npm test & rm x'), $ctx ), '&';
  ok !$allow->matches( bash('npm test $(rm x)'), $ctx ), 'command substitution';
  ok !$allow->matches( bash('npm test `rm x`'), $ctx ), 'backticks';
  ok !$allow->matches( bash('npm test > out.txt'), $ctx ), 'redirection into a file';
  ok !$allow->matches( bash('npm test >> out.txt'), $ctx ), 'appending redirection';
  ok !$allow->matches( bash('npm test <(cat x)'), $ctx ), 'process substitution';
  ok $allow->matches( bash('npm test 2>&1'), $ctx ), 'descriptor duplication is fine';
  ok $allow->matches( bash('npm test > /dev/null'), $ctx ), '/dev/null is fine';
  ok $allow->matches( bash('npm test "a && b"'), $ctx ), 'operators inside quotes do not split';
  ok $allow->matches( bash(q{npm test 'x; y'}), $ctx ), 'single quotes neither';
  ok !$allow->matches( bash(q{npm test "$(rm x)"}), $ctx ), 'substitution inside double quotes';

  my $whole = rule( 'Bash(make && make test)', 'allow' );
  ok $whole->matches( bash('make && make test'), $ctx ), 'an exact rule may name the whole command';
  ok !$whole->matches( bash('make && make test && rm x'), $ctx ), '... only exactly';

  my $deny = rule('Bash(rm:*)');
  ok $deny->matches( bash('npm test && rm -rf /'), $ctx ), 'deny: any part';
  ok $deny->matches( bash('ls | rm x'), $ctx ), 'deny: piped';
  ok $deny->matches( bash('echo $(rm -rf x)'), $ctx ), 'deny: inside $()';
  ok $deny->matches( bash('echo "$(rm -rf x)"'), $ctx ), 'deny: inside $() in double quotes';
  ok $deny->matches( bash('echo `rm -rf x`'), $ctx ), 'deny: inside backticks';
  ok $deny->matches( bash('(cd /tmp && rm x)'), $ctx ), 'deny: in a subshell';
  ok $deny->matches( bash('if true; then rm x; fi'), $ctx ), 'deny: after then';
  ok $deny->matches( bash('sudo rm x'), $ctx ), 'deny: behind sudo';
  ok $deny->matches( bash('FOO=1 rm x'), $ctx ), 'deny: behind an assignment';
  ok $deny->matches( bash('env A=b rm x'), $ctx ), 'deny: behind env';
  ok !$deny->matches( bash('echo rm x'), $ctx ), 'deny: an argument is not a command';
  ok !$deny->matches( bash(q{echo 'a; rm x'}), $ctx ), 'deny: not inside single quotes';

  ok rule('Bash(make && make test)')->matches( bash('make && make test'), $ctx ),
    'an exact deny rule matches the whole command';
};

subtest 'shell_parts' => sub {
  is $class->shell_parts('a && b || c; d | e'), { parts => [qw( a b c d e )], opaque => 0 }, 'operators';
  is $class->shell_parts('a $(b; c) d')->{parts}, [ 'b', 'c', 'a   d' ], 'substitution parts first';
  ok $class->shell_parts('a $(b) d')->{opaque}, 'substitution is opaque';
  ok $class->shell_parts(q{echo "unterminated})->{opaque}, 'unbalanced quotes are opaque';
  ok $class->shell_parts("cat <<EOF\nx\nEOF")->{opaque}, 'heredoc is opaque';
  ok !$class->shell_parts('a 2>&1 | b')->{opaque}, '2>&1 is not';
  ok $class->shell_parts('a >&out.txt')->{opaque}, '>&file is a file';
  ok $class->shell_parts('a &> f')->{opaque}, '&> into a file';
};

subtest 'path rules: Read and Edit' => sub {
  my $edit = rule( 'Edit(src/**)', 'allow' );
  ok $edit->matches( tc( write_file => { path => 'src/a/b.pm' } ), $ctx ), 'below the dir';
  ok $edit->matches( tc( edit_file  => { path => 'src/x' } ), $ctx ), 'edit_file too';
  ok $edit->matches( tc( write_file => { path => $root->child('src/x')->stringify } ), $ctx ), 'absolute path';
  ok !$edit->matches( tc( write_file => { path => 'lib/x' } ), $ctx ), 'not elsewhere';
  ok !$edit->matches( tc( write_file => { path => 'src/../lib/x' } ), $ctx ), '.. is resolved';
  ok !$edit->matches( tc( read_file  => { path => 'src/x' } ), $ctx ), 'Edit does not cover reading';

  my $deny = rule('Read(./secrets/**)');
  ok $deny->matches( tc( read_file => { path => 'secrets/key' } ), $ctx ), 'read_file';
  ok $deny->matches( tc( read_file => { path => 'lib/../secrets/key' } ), $ctx ), '../ trick';
  ok $deny->matches( tc( read_file => { path => 'lib/link/key' } ), $ctx ), 'symlink into the dir';
  ok $deny->matches( tc( list_files => { path => 'secrets' } ), $ctx ), 'the dir itself';
  ok !$deny->matches( tc( list_files => { path => '.' } ), $ctx ), 'listing the root is not reading it';
  ok !$deny->matches( tc( grep => { pattern => 'x' } ), $ctx ), 'grep over the root: the search tool hides the files';
  ok !$deny->matches( tc( glob => { pattern => '**', path => '.' } ), $ctx ), 'glob as well';
  ok $deny->matches( tc( grep => { pattern => 'x', path => 'secrets' } ), $ctx ), 'grep in the denied dir itself';
  ok $deny->matches( tc( glob => { pattern => '*', path => 'secrets/sub' } ), $ctx ), 'glob below it';
  ok $deny->matches( tc( grep => { pattern => 'x', path => 'lib/../secrets' } ), $ctx ), 'grep through ..';
  ok !rule( 'Read(./secrets/**)', 'allow' )->matches( tc( read_file => { path => 'lib/link/key' } ), $ctx ),
    'allow needs the written and the real path inside';

  my $env = rule('Read(.env)');
  ok $env->matches( tc( read_file => { path => '.env' } ), $ctx ), 'unanchored: top';
  ok $env->matches( tc( read_file => { path => 'a/b/.env' } ), $ctx ), 'unanchored: any depth';
  ok !$env->matches( tc( read_file => { path => 'a/.envrc' } ), $ctx ), 'unanchored: whole name';

  ok rule('Read(lib)')->matches( tc( read_file => { path => 'lib/x/y.pm' } ), $ctx ),
    'a matched directory covers what is below';
  ok rule('Read(*.pm)')->matches( tc( read_file => { path => 'lib/A.pm' } ), $ctx ), '* within a segment';
  ok !rule('Read(/*.pm)')->matches( tc( read_file => { path => 'lib/A.pm' } ), $ctx ), '/ anchors at the root';
  ok rule('Read(/lib/?.pm)')->matches( tc( read_file => { path => 'lib/A.pm' } ), $ctx ), '?';

  ok rule('Read(~/.ssh/**)')->matches( tc( read_file => { path => $home->child('.ssh/id')->stringify } ), $ctx ),
    '~/ is the home';
  ok rule('Read(//etc/**)')->matches( tc( read_file => { path => '/etc/passwd' } ), $ctx ), '// is absolute';
  ok rule('Read(//etc/**)')->matches( tc( read_file => { path => '../../../../../../../../etc/passwd' } ), $ctx ),
    '../ out of the root still lands on it';
};

subtest 'WebFetch domains' => sub {
  my $r = rule('WebFetch(domain:example.com)');
  ok $r->matches( tc( web_fetch => { url => 'https://example.com/x' } ), $ctx ), 'host';
  ok $r->matches( tc( web_fetch => { url => 'https://EXAMPLE.com/x' } ), $ctx ), 'case';
  ok !$r->matches( tc( web_fetch => { url => 'https://sub.example.com/' } ), $ctx ), 'not a subdomain';
  ok !$r->matches( tc( web_fetch => { url => 'https://example.com.evil.net/' } ), $ctx ), 'not a lookalike';
  ok $r->matches( tc( web_fetch => { url => 'https://user@example.com/' } ), $ctx ), 'userinfo';
  ok !$r->matches( tc( web_fetch => { url => 'https://example.com@evil.net/' } ), $ctx ), 'userinfo trick';
  my $sub = rule('WebFetch(domain:*.example.com)');
  ok $sub->matches( tc( web_fetch => { url => 'http://a.b.example.com' } ), $ctx ), 'subdomain';
  ok !$sub->matches( tc( web_fetch => { url => 'http://example.com' } ), $ctx ), 'not the base';
  ok !$sub->matches( tc( web_fetch => { url => 'http://badexample.com' } ), $ctx ), 'not a suffix';
};

subtest 'Agent, Task and Skill names' => sub {
  my $agent = rule('Agent(reviewer)');
  ok $agent->is_valid, 'Agent(name)';
  is $agent->tools, ['agent'], 'the agent tool';
  ok $agent->matches( tc( agent => { subagent_type => 'reviewer', prompt => 'x' } ), $ctx ), 'subagent_type';
  ok !$agent->matches( tc( agent => { subagent_type => 'reviewer2' } ), $ctx ), 'exact name';
  ok !$agent->matches( tc( agent => {} ), $ctx ), 'no subagent_type';
  ok rule('Task(reviewer)')->matches( tc( agent => { subagent_type => 'reviewer' } ), $ctx ), 'Task as well';
  ok rule('Agent')->matches( tc( agent => { subagent_type => 'x' } ), $ctx ), 'bare Agent: every agent';
  my $skill = rule('Skill(pdf)');
  ok $skill->matches( tc( skill => { skill => 'pdf' } ), $ctx ), 'Skill(name)';
  ok !$skill->matches( tc( skill => { skill => 'docx' } ), $ctx ), 'other skill';
  ok rule('Skill(plugin:pdf)')->matches( tc( skill => { skill => 'plugin:pdf' } ), $ctx ), 'plugin skill';
};

subtest 'MCP rules and foreign tools' => sub {
  my $foreign = { %$ctx, builtin => 0, server => 'github' };
  my $c = { name => 'create_issue', source => 'catalog:github', arguments => {} };
  ok rule('mcp__github__create_issue')->matches( $c, $foreign ), 'exact tool';
  ok rule('mcp__github')->matches( $c, $foreign ), 'server';
  ok rule('mcp__github__*')->matches( $c, $foreign ), 'server wildcard';
  ok !rule('mcp__gitlab')->matches( $c, $foreign ), 'other server';
  ok !rule('mcp__github__close_issue')->matches( $c, $foreign ), 'other tool';
  ok !rule('mcp__github')->matches( $c, $ctx ), 'never a built-in tool';

  my $fbash = { name => 'bash', source => 'catalog:shell', arguments => { command => 'ls' } };
  my $fctx  = { %$ctx, builtin => 0, server => 'shell' };
  ok rule('Bash')->matches( $fbash, $fctx ), 'a raider name denies a foreign tool of that name';
  ok !rule( 'Bash', 'allow' )->matches( $fbash, $fctx ), 'but never allows it';
};

done_testing;
