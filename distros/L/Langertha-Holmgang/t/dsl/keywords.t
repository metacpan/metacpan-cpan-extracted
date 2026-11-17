#!/usr/bin/env perl
# The keywords of the case DSL (ADR 0007), used inline -- outside the loader, where
# `suite` returns the suite and paths are relative to this file. Every suite here is
# invented (ADR 0003).
# Claims: each constructor returns the format 2 hash of its row in ADR 0007, and
# checks its own keys at once; each declaration writes its format 2 key into the
# innermost open block; a keyword outside its block, a single-valued keyword given
# twice, a duplicate case id, an unknown key -- each dies at the line that wrote it;
# run/put resolve to the one tool with that simulator when the suite closes, or the
# suite does not load; a qr// is kept as its string form; a refusal of the shared
# structure checks names this file, the case and the field; the collisions of ADR
# 0007 hold (rename on import, `no`, prototypes, `version::`).
use strict;
use warnings;
use FindBin;
use Path::Tiny qw( path );
use Test::More;

use Langertha::Holmgang;

my $FILE = path(__FILE__)->basename;

# a dies-at-this-line check: the code runs on the line that names $line
sub dies_at {
  my ( $code, $line, $re, $name ) = @_;
  eval { $code->() };
  my $err = $@;
  like( $err, $re, $name );
  like( $err, qr/ at \Q$0\E line $line\.$/m, '... at the line that wrote it' );
}

my %SWITCH = (
  description => 'Switch a lamp.',
  parameters  => { type => 'object', required => [qw( lamp on )],
                   properties => { lamp => { type => 'string' }, on => { type => 'integer' } } },
  handlers    => [ handler( apply => [ { set => 'lamps.{lamp}', value => '{on}' } ], output => 'ok' ) ],
);

# a valid case body around one extra declaration
sub lamp_case {
  my ( $extra ) = @_;
  return sub {
    title 'Hall light on';
    ask 'Switch the hall light on.';
    world lamps => { hall => 0, desk => 0 };
    rule 'hall on'        => at 'lamps.hall', equals => 1;
    rule 'desk untouched' => unchanged_except ['lamps.hall'];
    solution call switch => { lamp => 'hall', on => 1 };
    alternative 'desk off first' => call( switch => { lamp => 'desk', on => 0 } ), call( switch => { lamp => 'hall', on => 1 } );
    wrong 'the desk' => call switch => { lamp => 'desk', on => 1 };
    $extra->() if $extra;
  };
}

#### constructors: format 2 data, nothing recorded

is_deeply( call( switch => { lamp => 'hall' } ), { tool => 'switch', args => { lamp => 'hall' } }, 'call' );
is_deeply( call( switch => undef ), { tool => 'switch', args => {} }, 'call without arguments' );
is_deeply( [ at 'a.b', equals => 1, required => 0 ], [ { state => 'a.b', equals => 1, required => 0 } ], 'at: the rule kind state' );
is_deeply( at( 'n', equals => 4, tolerance => 0.5 ), { state => 'n', equals => 4, tolerance => 0.5 }, 'at: tolerance beside equals (k49)' );
is_deeply( unchanged_except( ['a'] ), { unchanged_except => ['a'] }, 'unchanged_except' );
is_deeply( calls( [ call( t => {} ) ], required => 0 ), { calls => [ { tool => 't', args => {} } ], required => 0 }, 'calls' );
is_deeply( not_called( call( t => { x => '^y' } ) ), { not_called => { tool => 't', args => { x => '^y' } } }, 'not_called' );
is_deeply( only_tools( [] ), { only_tools => [] }, 'only_tools' );
is_deeply( check( { host => 'h', command => 'c' }, expect => { exit => 0 } ),
  { check => { host => 'h', command => 'c' }, expect => { exit => 0 } }, 'check' );
is_deeply( packet( { host => 'h' }, verdict => 'drop', boot => 1 ), { packet => { host => 'h' }, verdict => 'drop', boot => 1 }, 'packet' );
is_deeply( login( { host => 'h' }, result => 'denied' ), { login => { host => 'h' }, result => 'denied' }, 'login' );
is_deeply( handler( match => { a => 'x' }, output => 'o', error => 1 ), { match => { a => 'x' }, output => 'o', error => 1 }, 'handler' );
is_deeply( haystack( kind => 'journal', tokens => 500 ), { generate => { kind => 'journal', tokens => 500 } }, 'haystack' );
is_deeply( image( 'img/a.png', untrusted => 1 ), { file => 'img/a.png', untrusted => 1 }, 'image' );
is( file('keywords.t') =~ /\A#!/ ? 1 : 0, 1, 'file: reads relative to the calling file' );

dies_at( sub { at 'a', equal => 1 }, __LINE__, qr/\Aat: unknown key 'equal'/, 'a constructor checks its keys' );
dies_at( sub { check { host => 'h' }, expected => {} }, __LINE__, qr/\Acheck: unknown key 'expected'/, '... check too' );
dies_at( sub { handler apply => [], outptu => 'x' }, __LINE__, qr/\Ahandler: unknown key 'outptu'/, '... handler too' );
dies_at( sub { image 'a.png', trusted => 1 }, __LINE__, qr/\Aimage: unknown key 'trusted'/, '... image too' );
dies_at( sub { file 'no-such-file.txt' }, __LINE__, qr/\Afile: cannot read no-such-file\.txt/, 'file: a missing file' );

#### declarations outside their block

dies_at( sub { ask 'hello' },        __LINE__, qr/\Aask: only inside a case block/, 'ask outside a case' );
dies_at( sub { title 'x' },          __LINE__, qr/\Atitle: only inside a suite or case block/, 'title outside a block' );
dies_at( sub { case c => sub { } },  __LINE__, qr/\Acase: only inside a suite block/, 'case outside a suite' );
dies_at( sub { tool x => ( %SWITCH ) }, __LINE__, qr/\Atool: only inside a suite block/, 'tool outside a suite' );
dies_at( sub { generate seed => 1, sub { } }, __LINE__, qr/\Agenerate: only inside a suite block/, 'generate outside a suite' );

#### a whole suite: every declaration writes its format 2 key

my $suite = suite 'kw-all' => sub {
  title       'All the keywords';
  description 'Invented.';
  version     3;
  topic       'probe';
  license     'Perl_5';
  repeat      2;
  threshold   pass_rate => 0.75;
  source      title => 'tests', url => 'https://example.org/';
  system_prompt 'Switch lamps.';
  settings    temperature => 0.5, max_tokens => 300, max_turns => 5;
  tool switch => %SWITCH;

  case 'b-second' => lamp_case( sub {
    difficulty 'schwer';
    weight     0.5;
    tags       'licht', 'verbot';
    tags       'x';
    tier       '48k';
    system_prompt 'Only the hall.';
    settings   max_turns => 3;
    source     title => 'case source';
    rule 'no other tool' => only_tools ['switch'];
    rule 'right lamp named' => calls [ call switch => { lamp => qr/^hall$/ } ], required => 0;
  } );
  case 'a-first' => lamp_case( sub {
    message assistant => 'Which one?';
    ask 'The hall.', untrusted => 1;
  } );
};

isa_ok( $suite, 'Langertha::Holmgang::Suite', 'suite returns the suite' );
is_deeply( { map { $_ => $suite->$_ } qw( id title description version topic license repeat threshold source defaults ) }, {
  id          => 'kw-all',
  title       => 'All the keywords',
  description => 'Invented.',
  version     => 3,
  topic       => 'probe',
  license     => 'Perl_5',
  repeat      => 2,
  threshold   => { pass_rate => 0.75 },
  source      => { title => 'tests', url => 'https://example.org/' },
  defaults    => { system => 'Switch lamps.', temperature => 0.5, max_tokens => 300, max_turns => 5 },
}, 'suite keywords' );
is_deeply( $suite->tools, [ { name => 'switch', %SWITCH } ], 'tool' );
is_deeply( [ map { $_->id } @{ $suite->cases } ], [qw( a-first b-second )], 'cases ordered by id' );

my ( $a1, $b2 ) = @{ $suite->cases };
is_deeply( $b2->tags, [qw( licht verbot x stufe-48k )], 'tags append, tier writes stufe-<tier>' );
is( $b2->tier, '48k', '... the case reads the tier' );
ok( $b2->is_hard, '... and the hardness from the tags' );
is( $b2->difficulty, 'schwer', 'difficulty' );
is( $b2->weight, 0.5, 'weight' );
is( $b2->system, 'Only the hall.', 'system_prompt in a case: system' );
is( $b2->max_turns, 3, 'settings in a case: the case key' );
is( $b2->effective('temperature'), 0.5, '... the rest falls back to the suite defaults' );
is_deeply( $b2->source, { title => 'case source' }, 'source in a case' );
is_deeply( $b2->rules, [
  { title => 'hall on', state => 'lamps.hall', equals => 1 },
  { title => 'desk untouched', unchanged_except => ['lamps.hall'] },
  { title => 'no other tool', only_tools => ['switch'] },
  { title => 'right lamp named', calls => [ { tool => 'switch', args => { lamp => "${\ qr/^hall$/ }" } } ], required => 0 },
], 'rule TITLE => KIND; a qr// kept as its string form' );
is_deeply( $b2->solution, [ { tool => 'switch', args => { lamp => 'hall', on => 1 } } ], 'solution' );
is_deeply( $b2->alternatives, [ { title => 'desk off first', calls => [
  { tool => 'switch', args => { lamp => 'desk', on => 0 } }, { tool => 'switch', args => { lamp => 'hall', on => 1 } } ] } ], 'alternative' );
is_deeply( $b2->wrong_solutions, [ { title => 'the desk', calls => [ { tool => 'switch', args => { lamp => 'desk', on => 1 } } ] } ], 'wrong' );
is_deeply( $b2->state, { lamps => { hall => 0, desk => 0 } }, 'world: an untyped state entry' );
is_deeply( $a1->messages, [
  { role => 'user', content => 'Switch the hall light on.' },
  { role => 'assistant', content => 'Which one?' },
  { role => 'user', content => 'The hall.', untrusted => 1 },
], 'ask and message, untrusted' );
ok( $a1->has_untrusted, '... the mark is the case\'s' );
like( $suite->digest, qr/\A[0-9a-f]{64}\z/, 'a digest' );

# what the blocks recorded is copied: a hash used twice is not shared
{
  my %lamps = ( hall => 0, desk => 0 );
  my $s = suite 'kw-copy' => sub {
    title 'copy'; version 1; tool switch => %SWITCH;
    case c => sub { lamp_case()->(); };
  };
  ok( $s->cases->[0]->state->{lamps} != \%lamps, 'the case holds its own copy' );
}

#### the "no tool" family: solution() is []

{
  my $s = suite 'kw-none' => sub {
    title 'none'; version 1; tool switch => %SWITCH;
    case c => sub {
      title 'Leave the lights';
      ask 'Is the hall light on? Do not touch anything.';
      world lamps => { hall => 0 };
      rule 'no tool' => only_tools [];
      solution();
      wrong 'switched anyway' => call switch => { lamp => 'hall', on => 1 };
    };
  };
  is_deeply( $s->cases->[0]->solution, [], 'solution() is []' );
  ok( $s->cases->[0]->no_tool, '... the "no tool" family' );
}

#### run and put: the one tool with that simulator

my %SHELL = ( simulator => 'run_command', description => 'Shell.',
  parameters => { type => 'object', required => [qw( host command )], properties => { host => { type => 'string' }, command => { type => 'string' } } } );
my %WRITE = ( simulator => 'write_file', description => 'Write.',
  parameters => { type => 'object', required => [qw( host path content )],
                  properties => { host => { type => 'string' }, path => { type => 'string' }, content => { type => 'string' } } } );
my $motd = sub {
  my ( @tools ) = @_;
  return sub {
    title 'motd'; version 1;
    tool @$_ for @tools;
    case c => sub {
      title 'Set the motd';
      ask 'Put "hi" into /etc/motd on box-1.';
      device 'box-1' => linux => { files => { '/etc/motd' => "old\n" } };
      observe match => { host => '^box-1$', command => '^uptime' }, output => 'up 1 day';
      rule 'motd says hi' => at [ 'box-1', 'files', '/etc/motd', 'content' ], regex => qr/\Ahi$/m;
      rule 'nothing else' => unchanged_except [ [ 'box-1', 'files', '/etc/motd' ] ];
      rule 'no reboot'    => not_called run 'box-1' => '^reboot';
      solution put 'box-1' => '/etc/motd' => "hi\n";
      alternative 'echo' => run 'box-1' => "echo hi > /etc/motd";
      wrong 'wrong file' => put 'box-1' => '/etc/issue' => "hi\n";
    };
  };
};
{
  my $s = suite 'kw-motd' => $motd->( [ shell => %SHELL ], [ write => %WRITE ] );
  my $c = $s->cases->[0];
  is_deeply( $c->solution, [ { tool => 'write', args => { host => 'box-1', path => '/etc/motd', content => "hi\n" } } ], 'put: the write_file tool' );
  is_deeply( $c->alternatives->[0]{calls}, [ { tool => 'shell', args => { host => 'box-1', command => 'echo hi > /etc/motd' } } ], 'run: the run_command tool' );
  is_deeply( $c->rules->[2], { title => 'no reboot', not_called => { tool => 'shell', args => { host => 'box-1', command => '^reboot' } } },
    'run as a call pattern' );
  is( $c->rules->[0]{regex}, "${\ qr/\Ahi$/m }", 'qr// with flags kept as its string form' );
  is_deeply( $c->observe, [ { match => { host => '^box-1$', command => '^uptime' }, output => 'up 1 day' } ], 'observe' );
  is_deeply( $c->state, { 'box-1' => { type => 'linux', files => { '/etc/motd' => "old\n" } } }, 'device NAME => TYPE => {...}' );
}
{
  my $line;
  eval { suite 'kw-motd' => $motd->( [ write => %WRITE ] ) };
  like( $@, qr/\Arun: the suite needs exactly one tool with simulator run_command, it has 0 at \Q$0\E line \d+\./, 'run without a run_command tool: does not load' );
  eval { suite 'kw-motd' => $motd->( [ shell => %SHELL ], [ shell2 => %SHELL ], [ write => %WRITE ] ) };
  like( $@, qr/\Arun: the suite needs exactly one tool with simulator run_command, it has 2 /, '... nor with two' );
}

#### once per block, one tier, unique ids, no nesting

dies_at( sub { suite 'kw-x' => sub { title 'a'; title 'b' } }, __LINE__, qr/\Atitle: given twice in suite kw-x/, 'title twice in a suite' );
dies_at( sub { suite 'kw-x' => sub { version 1; settings max_turns => 2; settings max_turns => 3 } }, __LINE__,
  qr/\Asettings max_turns: given twice/, 'a setting twice' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { solution(); solution() } } }, __LINE__, qr/\Asolution: given twice in case c/, 'solution twice' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { tier '16k'; tier '48k' } } }, __LINE__, qr/\Atier: one tier per case/, 'tier twice' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { tags 'stufe-16k'; tier '48k' } } }, __LINE__, qr/\Atier: one tier per case/, 'tier beside a stufe tag' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { tier '48k'; tags 'stufe-16k' } } }, __LINE__, qr/\Atags: one tier per case/, 'a stufe tag beside tier' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { tier 'long' } } }, __LINE__, qr/\Atier: a length tier like '48k' expected/, 'tier checked' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { }; case c => sub { } } }, __LINE__, qr/\Acase: id 'c' twice in suite kw-x/, 'case id twice' );
dies_at( sub { suite 'kw-x' => sub { suite 'kw-y' => sub { } } }, __LINE__, qr/\Asuite: a suite does not nest/, 'no nested suite' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { case d => sub { } } } }, __LINE__, qr/\Acase: only inside a suite block/, 'no case in a case' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { device h => linux => { type => 'linux' } } } }, __LINE__,
  qr/\Adevice: the type is the second argument/, 'device: no type key in the state' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { world a => 1; device a => linux => {} } } }, __LINE__,
  qr/\Adevice: a twice in the state/, 'a state entry twice' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { rule 'r' => { title => 'x', state => 'a' } } } }, __LINE__,
  qr/\Arule: TITLE => KIND expected/, 'rule: a kind, not a titled hash' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { rule 'r' => at( 'a', exists => 1 ), required => 0 } } }, __LINE__,
  qr/\Arule: TITLE => KIND expected/, 'rule: the pairs belong to the kind' );
dies_at( sub { suite 'kw-x' => sub { case c => sub { solution 'switch' } } }, __LINE__,
  qr/\Asolution: calls expected/, 'solution: calls only' );
dies_at( sub { suite 'kw-x' => sub { generate sub { } } }, __LINE__, qr/\Agenerate: seed missing/, 'generate needs a seed' );
dies_at( sub { suite 'kw-x' => sub { generate seed => -1, sub { } } }, __LINE__, qr/\Agenerate: seed must be an integer/, 'generate checks the seed' );

#### the shared structure checks: a refusal names this file, the case and the field

{
  eval {
    suite 'kw-bad' => sub {
      title 'bad'; version 1; tool switch => %SWITCH;
      case c1 => lamp_case( sub { rule 'r' => at 'lamps.hall', equals => [1] } );
    };
  };
  my $e = Langertha::Holmgang::Error->caught($@);
  ok( $e, 'a structure refusal is a Langertha::Holmgang::Error' ) or diag $@;
  is( $e && $e->field, "$FILE: case c1: rules[2].equals", '... naming file, case and field' );
  eval { suite 'kw-bad' => sub { title 'bad'; tool switch => %SWITCH; case c1 => lamp_case() } };
  like( "$@", qr/\A\Q$FILE\E: version: integer/, 'a head refusal names the file' );
  eval { suite 'kw-bad' => sub { title 'bad'; version 1; tool switch => ( %SWITCH, description => '' ); case c1 => lamp_case() } };
  like( "$@", qr/\A\Q$FILE\E: tools\[0\]\.description: text missing/, '... a tool too' );
  eval { suite 'kw-bad' => sub { title 'bad'; version 1; tool switch => %SWITCH } };
  like( "$@", qr/\A\Q$FILE\E: no cases/, 'a suite without cases does not load' );
  eval {
    suite 'kw-bad' => sub {
      title 'bad'; version 1; tool switch => %SWITCH;
      case c1 => lamp_case( sub { wrong 'harmless' => call switch => { lamp => 'hall', on => 1 } } );
    };
  };
  like( "$@", qr/\A\Q$FILE\E: case c1: wrong_solutions\[1\]/, 'lint runs: a wrong solution that passes refuses the suite' );
  eval {
    suite 'kw-bad' => sub {
      title 'bad'; version 1; tool switch => %SWITCH;
      case c1 => lamp_case( sub { device h => 'no-such-type' => {} } );
    };
  };
  like( "$@", qr/\A\Q$FILE\E: case c1: state\.h\.type: device type /, 'a device type is checked against the registry when the suite closes' );
  eval {
    suite 'kw-bad' => sub {
      title 'bad'; version 1; tool switch => %SWITCH;
      case c1 => lamp_case( sub { ask [ 'text', haystack kind => 'journal', tokens => 200, colour => 'red' ] } );
    };
  };
  like( "$@", qr/\A\Q$FILE\E: case c1: messages\[1\]\.content.*colour/, 'haystack keys are checked when the suite closes' );
}

#### collisions (ADR 0007)

{
  package Local::Renamed;
  use Langertha::Holmgang call => { -as => 'tool_call' };
  ::ok( !__PACKAGE__->can('call'), 'rename on import: call is not there' );
  ::is_deeply( tool_call( t => {} ), { tool => 't', args => {} }, '... tool_call is' );
}
{
  package Local::Removed;
  use Langertha::Holmgang;
  no Langertha::Holmgang;
  ::ok( !__PACKAGE__->can($_), "no Langertha::Holmgang removes $_" ) for qw( suite case rule run file version );
}
{
  is( version::->parse('1.2.3')->normal, 'v1.2.3', 'version:: still reaches the core package' );
  eval q{ my @x = ( run a => 'x', run b => 'y' ); 1 };
  like( $@, qr/Too many arguments for .*run/, 'run($$): a comma list without parentheses does not compile' );
  my @two = ( run( a => 'x' ), run( b => 'y' ) );
  is( scalar @two, 2, '... with parentheses it is two calls' );
  my @after = ( file 'keywords.t', 'next' );
  is( scalar @after, 2, 'file($) does not swallow what follows' );
}

done_testing;
