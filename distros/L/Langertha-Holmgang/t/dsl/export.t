#!/usr/bin/env perl
# The YAML export of a DSL suite (k19, ADR 0007 amendment k19), on an invented suite
# (ADR 0003).
# Claims: Loader->export writes suite.yaml, cases/<id>.yaml and the images a case
# shows, and nothing else (no suite.pl, no text file read by `file`); the export
# loads back through the format 2 loader into the same structure -- head, every
# case's own keys, initial state, what the model is sent, images, derived values,
# mock runs with their requests -- and with the same digest, which is the DSL
# suite's own (ADR 0007: a suite and its export are the same suite); generated
# content stays a generate spec, generated cases are plain cases, texts read by
# `file` are inline; the bytes are canonical (two exports, and an export in another
# process under another hash seed, are byte-identical) and readable (a text with line
# breaks is a literal block, a numeric text stays a text, a number a number);
# DSL cases run in the export's file-name order (`a-b` before `a`); the loader's seed
# override is exported; a format 2 suite, an existing target and a value without a
# format 2 image are refused. Through the command line: export-yaml writes, skips
# format 2 suites, refuses an existing target before writing (exit 2). (--seed on
# the command line: t/cli/seed.t.) Network-free: Langertha::Engine::Virtual.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use IPC::Open3 ();
use Path::Tiny qw( path );
use Test::More;

use Holmgang::CLI qw( cli );
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Structure;
use Langertha::Holmgang::Target;

my $png = path( $FindBin::Bin, '..', '..', 'share', 'suites', 'demo-sehen', 'img', 'ablauf.png' );
plan skip_all => 'no share/suites/demo-sehen/img/ablauf.png next to t/' unless -f $png;

my $tmp = Path::Tiny->tempdir;

sub suite_pl {
  my ( $id, $extra ) = @_;
  $extra //= '';
  return <<"P";
use Langertha::Holmgang;
use utf8;

suite '$id' => sub {
  title       'Export: one suite, written out';
  version     3;
  description "Invented for the export test.\\nTwo lines, the second: with a colon.";
  license     'Perl_5';
  source      title => 'holmgang tests', license => 'Perl_5', authors => 'Zoë Example';
  topic       'probe';
  threshold   pass_rate => 0.5;
  system_prompt file 'system.md';
  settings    temperature => 0.25, max_turns => 6;

  tool run_command => (
    simulator   => 'run_command',
    description => 'Run a shell command on a host.',
    parameters  => { type => 'object', required => [qw( host command )],
                     properties => { host => { type => 'string' }, command => { type => 'string' } } },
  );
  tool write_file => (
    simulator   => 'write_file',
    description => 'Replace a file on a host.',
    parameters  => { type => 'object', required => [qw( host path content )],
                     properties => { host => { type => 'string' }, path => { type => 'string' }, content => { type => 'string' } } },
  );
  tool set_level => (
    description => 'Set a level: 0, 1 or 2.',
    parameters  => { type => 'object', required => ['level'],
                     properties => { level => { type => 'string', enum => [ '0', '1', '2' ] } } },
    handlers => [ handler match => { level => qr/^[0-2]\$/ },
                          apply => [ { set => 'level', value => '{level}' } ], output => 'ok' ],
  );
  $extra

  generate seed => 31337, sub {
    my ( \$rng ) = \@_;
    my \@levels = \$rng->shuffle( '0', '1', '2' );
    for my \$i ( 0, 1 ) {
      my \$want = \$levels[\$i];
      case 'level-'.( \$i ? 'b' : 'a' ) => sub {
        title 'Set the level to '.\$want;
        world level => undef;
        world notes => { lines => "one\\n\\n", lead => "  indented\\nx", tab => "a\\tb\\n", yes => 'yes',
                         number => 5, numeric => '5', colon => 'a: b', empty => '', dash => '-x', umlaut => 'Größe',
                         sep => "\\x{2028}y\\nz", nothing => undef };
        ask 'Set the level to '.\$want.'.';
        rule 'level set' => at 'level', equals => \$want;
        rule 'nothing else' => unchanged_except ['level'];
        solution call set_level => { level => \$want };
        alternative 'zero first' => call( set_level => { level => '0' } ), call( set_level => { level => \$want } );
        wrong 'another level' => call set_level => { level => \$levels[2] };
      };
    }
  };

  case a => sub {
    title 'Read the journal, then the picture';
    tags  'bild';
    tier  '16k';
    weight 2;
    ask [ "The journal of box-9:\\n\\n", haystack( kind => 'journal', tokens => 1000, seed => 5, host => 'box-9' ) ];
    message assistant => 'Read.';
    ask 'Now the picture; then write the motd.', images => [ 'img/flow.png', image( 'img/flow.png', untrusted => 1 ) ];
    device 'web-1' => linux => { files => { '/etc/motd' => "Hello.\\n" } };
    rule 'motd' => at [ 'web-1', 'files', '/etc/motd', 'content' ], regex => qr/^Window\\b/;
    rule 'only the motd' => unchanged_except [ [ 'web-1', 'files', '/etc/motd' ] ];
    solution put 'web-1' => '/etc/motd' => "Window Sunday 05:00.\\n";
    alternative 'look first' => run( 'web-1' => 'uptime' ), put( 'web-1' => '/etc/motd' => "Window Sunday 05:00.\\n" );
    wrong 'the issue file' => put 'web-1' => '/etc/issue' => "Window Sunday 05:00.\\n";
  };

  case 'a-b' => sub {
    title 'Note the status, through the shell';
    ask 'On web-1, write "up" into /etc/status with a shell command.';
    device 'web-1' => linux => { files => { '/etc/motd' => "Hello.\\n" } };
    rule 'status written' => at [ 'web-1', 'files', '/etc/status', 'content' ], equals => "up\\n";
    rule 'no write_file' => not_called call write_file => {};
    solution run 'web-1' => 'echo up > /etc/status';
    alternative 'look first' => run( 'web-1' => 'uptime' ), run( 'web-1' => 'echo up > /etc/status' );
    wrong 'with write_file' => put 'web-1' => '/etc/status' => "up\\n";
  };
};
P
}

sub dsl_dir {
  my ( $root, $id, $code ) = @_;
  my $d = path( $root, $id );
  $d->child('img')->mkpath;
  $d->child('suite.pl')->spew_utf8($code);
  $d->child('system.md')->spew_utf8("Work through the tools.\nAnswer briefly.\n");
  $png->copy( $d->child( 'img', 'flow.png' ) );
  return "$d";
}

my $dir    = dsl_dir( $tmp->child('dsl'), 'ex-export', suite_pl('ex-export') );
my $loader = Langertha::Holmgang::Loader->new;
my $dsl    = eval { $loader->load($dir) };
ok( $dsl, 'the DSL suite loads' ) or diag $@;
BAIL_OUT('the DSL suite does not load') unless $dsl;

#### the export

my $root = $tmp->child('out');
my $out  = eval { $loader->export( $dir, "$root" ) };
is( $out, $root->child('ex-export')->stringify, 'export writes into ROOT/<id>' ) or diag $@;
BAIL_OUT('no export') unless $out;
my $o = path($out);
is_deeply( [ sort map { $_->relative($o)->stringify } grep { -f } map { $_ } $o->children, $o->child('cases')->children, $o->child('img')->children ],
  [qw( cases/a-b.yaml cases/a.yaml cases/level-a.yaml cases/level-b.yaml img/flow.png suite.yaml )],
  'suite.yaml, one file per case, the image; no suite.pl, no system.md' );
is( $o->child( 'img', 'flow.png' )->slurp_raw, $png->slurp_raw, '... the image byte for byte' );
is_deeply( [ grep { /\A\./ } map { $_->basename } $root->children ], [], '... no temporary directory left' );

my $yaml = eval { $loader->load($out) };
ok( $yaml, 'the export loads as format 2 (structure, lint, mock runs)' ) or diag $@;
BAIL_OUT('the export does not load') unless $yaml;
is( $yaml->digest, $dsl->digest, 'the same digest: a suite and its export are the same suite' );

is_deeply( { map { $_ => $yaml->$_ } qw( id version title description license source topic threshold repeat defaults tools ) },
  { map { $_ => $dsl->$_ } qw( id version title description license source topic threshold repeat defaults tools ) },
  'suite head identical' );
is_deeply( [ map { $_->id } @{ $dsl->cases } ], [qw( a-b a level-a level-b )], 'DSL cases in the export\'s file-name order (a-b before a)' );
is_deeply( [ map { $_->id } @{ $yaml->cases } ], [ map { $_->id } @{ $dsl->cases } ], '... the order the export loads in' );

for my $i ( 0 .. $#{ $dsl->cases } ) {
  my ( $cd, $cy ) = ( $dsl->cases->[$i], $yaml->cases->[$i] );
  my $id = $cd->id;
  is_deeply( $cy->$_, $cd->$_, "$id: $_ identical" ) for @Langertha::Holmgang::Structure::CASE_KEYS;
  is_deeply( $cy->initial_state,   $cd->initial_state,   "$id: initial state identical" );
  is_deeply( $cy->prompt_messages, $cd->prompt_messages, "$id: what the model is sent identical" );
  my $strip = sub { my ( $c ) = @_; return { map { my %i = %{ $c->image_files->{$_} }; delete $i{path}; ( $_ => \%i ) } keys %{ $c->image_files } } };
  is_deeply( $strip->($cy), $strip->($cd), "$id: images identical (but the directory)" );
  is_deeply( [ map { $cy->$_ } qw( tier effective_weight is_hard has_untrusted has_images no_tool ) ],
    [ map { $cd->$_ } qw( tier effective_weight is_hard has_untrusted has_images no_tool ) ], "$id: derived values identical" );
  for my $mode (qw( solution text )) {
    my %r;
    for my $c ( [ dsl => $cd ], [ yaml => $cy ] ) {
      my $e   = Langertha::Holmgang::Runner->mock_engine( $c->[1], $mode );
      my $res = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ) )->run_case( $c->[1] );
      $r{ $c->[0] } = { ( map { $_ => $res->{$_} } qw( status rules diff calls answer state transcript ) ), requests => $e->requests };
    }
    is_deeply( $r{yaml}, $r{dsl}, "$id: mock $mode run identical, requests included" );
  }
}

#### what the files say

{
  my $head = $o->child('suite.yaml')->slurp_utf8;
  like( $head, qr/\Aformat: 2\nid: ex-export\n/, 'suite.yaml starts with format and id' );
  like( $head, qr/^  system: \|\n    Work through the tools\.\n    Answer briefly\.\n/m, 'the text `file` read: inline, a literal block' );
  like( $head, qr/^description: \|-\n  Invented for the export test\.\n  Two lines, the second: with a colon\.\n/m, '... without a final line break: |-' );
  like( $head, qr/^  authors: Zoë Example$/m, 'non-ASCII text plain, as UTF-8' );
  like( $head, qr/^            - "0"\n            - "1"\n            - "2"$/m, 'numeric texts quoted: an enum of strings stays strings' );
  unlike( $head, qr/generate|31337/, 'no trace of the generator in the head' );

  my $a = $o->child( 'cases', 'a.yaml' )->slurp_utf8;
  like( $a, qr/^      - generate:\n          host: box-9\n          kind: journal\n          seed: 5\n          tokens: 1000$/m,
    'a haystack stays a generate spec' );
  like( $a, qr/^    regex: "\(\?\^:\^Window\\\\b\)"$/m, 'a qr// as its string form' );
  like( $a, qr/^  - stufe-16k$/m, 'tier as its tag' );

  my $lv = $o->child( 'cases', 'level-a.yaml' )->slurp_utf8;
  like( $lv, qr/^    lines: \|\+\n      one\n\n/m, 'two final line breaks: |+' );
  like( $lv, qr/^    lead: "  indented\\nx"$/m, 'an indented first line: double-quoted' );
  like( $lv, qr/^    tab: \|\n      a\tb$/m, 'a tab inside a literal block' );
  like( $lv, qr/^    \Q$_\E$/m, "scalar: $_" ) for '"yes": "yes"', 'number: 5', 'numeric: "5"', 'colon: "a: b"', 'empty: ""', 'dash: "-x"', 'umlaut: Größe', 'nothing: ~', 'sep: "\\u2028y\\nz"';
  unlike( $lv, qr/generate|31337|shuffle/, 'a generated case is a plain case' );
}

#### canonical bytes

sub tree {
  my ( $d ) = @_;
  my %t;
  $d->visit( sub { $t{ $_[0]->relative($d)->stringify } = $_[0]->slurp_raw if -f $_[0] }, { recurse => 1 } );
  return \%t;
}
{
  my $again = $loader->export( $dir, $tmp->child('out2')->stringify );
  is_deeply( tree( path($again) ), tree($o), 'a second export: byte for byte the same' );

  my $third = $tmp->child('out3');
  local $ENV{PERL_HASH_SEED}   = 4242;
  local $ENV{PERL_PERTURB_KEYS} = 2;
  my $code = sprintf( 'Langertha::Holmgang::Loader->new->export( q{%s}, q{%s} )', $dir, "$third" );
  my $pid = IPC::Open3::open3( my $in, my $rd, undef, $^X, ( map { "-I$_" } @INC ), '-MLangertha::Holmgang::Loader', '-e', $code );
  my $msg = do { local $/; <$rd> };
  waitpid $pid, 0;
  is( $?, 0, 'an export in another process under another hash seed' ) or diag $msg;
  is_deeply( tree( $third->child('ex-export') ), tree($o), '... byte for byte the same' );
}

#### seed override

{
  my $seeded = Langertha::Holmgang::Loader->new( seeds => { 'ex-export' => 7 } );
  my $s   = $seeded->load($dir);
  my $out = $seeded->export( $dir, $tmp->child('seeded')->stringify );
  is( Langertha::Holmgang::Loader->new->load($out)->digest, $s->digest, 'with a seed override: the export is the overridden suite' );
  isnt( $s->digest, $dsl->digest, '... which is another suite' );
}

#### refusals

sub refused {
  my ( $code, $field, $reason, $name ) = @_;
  my $ok = eval { $code->(); 1 };
  my $e  = $@;
  ok( !$ok, $name ) or return;
  my $f = ref $e && $e->can('field') ? $e->field : '';
  like( $f, $field, '... field '.$f );
  like( ref $e && $e->can('reason') ? $e->reason : "$e", $reason, '... reason' );
}
refused( sub { $loader->export( path( $FindBin::Bin, '..', '..', 'share', 'suites', 'demo-lamp' )->stringify, $tmp->child('x')->stringify ) },
  qr/\Asuite\z/, qr/format 2 is YAML already/, 'a format 2 suite is not exported' );
{
  my $before = tree($o);
  refused( sub { $loader->export( $dir, "$root" ) }, qr/\Aexport\z/, qr/exists already/, 'an existing target is refused' );
  is_deeply( tree($o), $before, '... and left as it was' );
}
{
  # Structure lets a code reference in the state through to the world's copy,
  # which dies without a field (noted on k19); the export's own refusal:
  my $bad = dsl_dir( $tmp->child('bad'), 'ex-export', suite_pl( 'ex-export', q{ case zz => sub { title 'code'; world x => { cb => sub { 1 } }; ask 'x'; rule 'r' => at 'x', exists => 1; solution(); }; } ) );
  ok( !eval { $loader->load($bad); 1 }, 'a code reference in the state does not load' );
  refused( sub { $loader->_export_yaml( { id => 'zz', state => { x => { cb => sub { 1 } } } }, 'cases/zz.yaml', 'suite.pl: case zz' ) },
    qr/\Asuite\.pl: case zz\z/, qr/no format 2 image: a CODE reference/, 'the export writer refuses a value YAML cannot hold, naming the case' );
}

#### the command line

{
  my $cli_root = $tmp->child('cli');
  my $search   = $tmp->child('search');
  dsl_dir( $search, 'ex-export', suite_pl('ex-export') );
  path( $FindBin::Bin, '..', '..', 'share', 'suites', 'demo-lamp' )->visit(
    sub { my $t = $search->child( 'demo-lamp', $_[0]->relative( path( $FindBin::Bin, '..', '..', 'share', 'suites', 'demo-lamp' ) ) ); -d $_[0] ? $t->mkpath : do { $t->parent->mkpath; $_[0]->copy($t) } },
    { recurse => 1 } );
  my ( $code, $outp, $err ) = cli( 'export-yaml', "$search", '--out', "$cli_root" );
  is( $code, 0, 'export-yaml over a search directory: exit 0' ) or diag $outp.$err;
  like( $outp, qr/^skip demo-lamp \(format 2 already\)$/m, '... a format 2 suite skipped' );
  like( $outp, qr/^ok   ex-export \(4 cases\) -> \Q$cli_root\E\/ex-export$/m, '... the DSL suite written' );
  like( $outp, qr/^1 DSL suite: 1 exported, 0 refused$/m, '... the count' );
  is_deeply( tree( $cli_root->child('ex-export') ), tree($o), '... the same bytes as Loader->export' );

  ( $code, $outp, $err ) = cli( 'export-yaml', "$search", '--out', "$cli_root" );
  is( $code, 2, 'again into the same directory: exit 2' );
  like( $err, qr/exists already, nothing is overwritten/, '... nothing overwritten' );
  ( $code, $outp, $err ) = cli( 'export-yaml', "$search" );
  is( $code, 2, 'without --out: exit 2' );
  ( $code, $outp, $err ) = cli( 'export-yaml', path( $search, 'demo-lamp' )->stringify, '--out', "$cli_root" );
  is( $code, 2, 'no DSL suite named: exit 2' );
  like( $err, qr/no suite in the case DSL/, '... said so' );
}

done_testing;
