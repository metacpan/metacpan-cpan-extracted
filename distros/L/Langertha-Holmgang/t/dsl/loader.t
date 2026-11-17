#!/usr/bin/env perl
# DSL suites in search directories (ADR 0007, "Where DSL suites live"), on invented
# suites only (ADR 0003).
# Claims: a directory with suite.pl loads through the loader -- and is listed,
# located and linted by the command line like a format 2 suite; suite.yaml and
# suite.pl together, a suite.pl without a suite or with two, an id that is not the
# directory name, and a file that does not compile are refused with the field
# suite.pl; every file runs in a package of its own; `file` and images are relative
# to the suite directory; generate gives the same cases for the same seed, other
# cases for another, and the loader's seed override replaces the file's seed; the
# digest of a generated suite is the same in two processes with different hash
# seeds (the check that sees a keys-%h loop in a generator).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use IPC::Open3 ();
use Path::Tiny qw( path );
use Test::More;

use Holmgang::CLI qw( cli );
use Langertha::Holmgang::Loader;

my $tmp = Path::Tiny->tempdir;

# a generated suite: sums of numbers the random source draws; an extra line can be
# put into the suite block
sub sums_pl {
  my ( $id, %o ) = @_;
  my $seed  = $o{seed} // 4711;
  my $extra = $o{extra} // '';
  return <<"P";
use Langertha::Holmgang;

sub helper { 'defined in every suite file' }

suite '$id' => sub {
  title   'Sums';
  version 1;
  system_prompt file 'system.md';
  tool submit => (
    description => 'Hand in the sum.',
    parameters  => { type => 'object', required => ['value'], properties => { value => { type => 'integer' } } },
    handlers    => [ handler apply => [ { set => 'answer', value => '{value|int}' } ], output => 'ok' ],
  );
  $extra
  generate seed => $seed, sub {
    my ( \$rng ) = \@_;
    my %by_name = map { ( "n\$_" => \$rng->int( 10, 99 ) ) } 1 .. 3;
    for my \$name ( sort keys %by_name ) {
      my \$n = \$by_name{\$name};
      case "sum-\$name" => sub {
        title 'Double '.\$n;
        world answer => undef;
        ask 'What is '.\$n.' plus '.\$n.'? Hand it in.';
        rule 'sum handed in' => at 'answer', equals => 2 * \$n;
        rule 'nothing else'  => unchanged_except ['answer'];
        solution call submit => { value => 2 * \$n };
        alternative 'twice' => call( submit => { value => 1 } ), call( submit => { value => 2 * \$n } );
        wrong 'off by one' => call submit => { value => 2 * \$n + 1 };
      };
    }
  };
};
P
}

sub dsl_dir {
  my ( $root, $id, $code, %files ) = @_;
  my $d = path( $root, $id );
  $d->mkpath;
  $d->child('suite.pl')->spew_utf8($code);
  $d->child('system.md')->spew_utf8("Answer through the tool.\n");
  $d->child($_)->spew_utf8( $files{$_} ) for keys %files;
  return "$d";
}

my $loader = Langertha::Holmgang::Loader->new;
my $root   = $tmp->child('suites');

#### a suite.pl loads like a format 2 suite

my $dir = dsl_dir( $root, 'dsl-sums', sums_pl('dsl-sums') );
my $s = eval { $loader->load($dir) };
ok( $s, 'suite.pl loads (structure, lint, mock runs)' ) or diag $@;
is( $s && $s->id, 'dsl-sums', '... the declared suite' );
is( $s && $s->defaults->{system}, "Answer through the tool.\n", 'file: relative to the suite directory' );
is_deeply( [ map { $_->id } @{ $s ? $s->cases : [] } ], [qw( sum-n1 sum-n2 sum-n3 )], 'generated cases, ordered by id' );

my $again = $loader->load($dir);
is( $again->digest, $s->digest, 'same seed: same suite, same digest' );
is_deeply( [ map { $_->messages } @{ $again->cases } ], [ map { $_->messages } @{ $s->cases } ], '... same cases' );

{
  my $other = Langertha::Holmgang::Loader->new( seeds => { 'dsl-sums' => 90210 } )->load($dir);
  isnt( $other->digest, $s->digest, 'seed override: another suite' );
  isnt( join( '|', map { $_->messages->[0]{content} } @{ $other->cases } ),
    join( '|', map { $_->messages->[0]{content} } @{ $s->cases } ), '... other numbers' );
  my $d2 = dsl_dir( $tmp->child('override'), 'dsl-sums', sums_pl( 'dsl-sums', seed => 90210 ) );
  is( Langertha::Holmgang::Loader->new->load($d2)->digest, $other->digest, '... the same as that seed written into the file' );
  is( Langertha::Holmgang::Loader->new( seeds => { 'other-suite' => 1 } )->load($dir)->digest, $s->digest,
    '... an override for another id changes nothing' );
}

#### list, locate, the command line

my $yaml_root = $tmp->child('yaml');
{
  my $d = $yaml_root->child('fmt-two');
  $d->child('cases')->mkpath;
  $d->child('suite.yaml')->spew_utf8(<<'Y');
format: 2
id: fmt-two
version: 1
title: Format 2 beside the DSL
tools:
  - name: fan_set
    description: Sets the fan level.
    parameters: { type: object, required: [level], properties: { level: { type: string, enum: [off, high] } } }
    handlers: [ { apply: [ { set: fan.level, value: '{level}' } ], output: ok } ]
Y
  $d->child( 'cases', 'c1.yaml' )->spew_utf8(<<'Y');
id: c1
title: Cool the room
messages: [ { role: user, content: "It is hot in here." } ]
state: { fan: { level: off } }
rules:
  - { title: fan on high, state: fan.level, equals: high }
  - { title: nothing else, unchanged_except: [ fan.level ] }
solution: [ { tool: fan_set, args: { level: high } } ]
alternatives: [ { title: twice, calls: [ { tool: fan_set, args: { level: high } }, { tool: fan_set, args: { level: high } } ] } ]
wrong_solutions: [ { title: off, calls: [ { tool: fan_set, args: { level: off } } ] } ]
Y
}
{
  my $list = $loader->list( "$root:$yaml_root" );
  is_deeply( [ map { [ $_->{id}, $_->{error} ] } @$list ], [ [ 'dsl-sums', undef ], [ 'fmt-two', undef ] ], 'list: a DSL suite beside a format 2 suite' );
  is( $list->[0]{digest}, $s->digest, '... with its digest' );
  is( $list->[0]{cases}, 3, '... and its cases' );
  is( $loader->locate( "$root:$yaml_root", 'dsl-sums' ), "$root/dsl-sums", 'locate finds a suite.pl directory' );
  my ( $code, $out ) = cli( 'lint', "$root" );
  is( $code, 0, 'holmgang lint on a directory with a DSL suite' ) or diag $out;
  like( $out, qr/^ok   dsl-sums \(3 cases\)$/m, '... lints it' );
  ( $code, $out ) = cli( 'run', '--suite', "$root/dsl-sums", '--target', 'mock-solution' );
  is( $code, 0, 'holmgang run on a DSL suite with mock-solution passes' ) or diag $out;
}

#### refusals

sub refused {
  my ( $dir, $field, $reason, $name ) = @_;
  my $got = eval { Langertha::Holmgang::Loader->new->load($dir); 1 };
  my $e = Langertha::Holmgang::Error->caught($@);
  ok( !$got && $e, $name ) or return diag( $@ || 'loaded' );
  is( $e->field, $field, '... field '.$field );
  like( $e->reason, $reason, '... reason' );
}

{
  my $both = dsl_dir( $tmp->child('both'), 'dsl-both', sums_pl('dsl-both'), 'suite.yaml' => "format: 2\n" );
  refused( $both, 'suite', qr/suite\.yaml and suite\.pl/, 'suite.yaml and suite.pl in one directory' );
  my ( $list ) = $loader->list( $tmp->child('both')->stringify );
  like( $list->[0]{error}, qr/\Asuite: suite\.yaml and suite\.pl/, '... listed with the error' );

  refused( dsl_dir( $tmp->child('id'), 'dsl-dirname', sums_pl('dsl-other') ), 'suite.pl: id', qr/must be 'dsl-dirname'/,
    'the id must be the directory name' );
  refused( dsl_dir( $tmp->child('none'), 'dsl-none', "use Langertha::Holmgang;\n1;\n" ), 'suite.pl', qr/declares no suite/,
    'a suite.pl without a suite' );
  my $second = 1 + ( () = sums_pl('dsl-two') =~ /\n/g );    # the line after the first suite
  refused( dsl_dir( $tmp->child('two'), 'dsl-two', sums_pl('dsl-two')."suite 'dsl-two' => sub { };\n" ), 'suite.pl',
    qr/\Asuite: a suite\.pl declares exactly one suite at \S+suite\.pl line $second\./, 'two suites in one file' );
  refused( dsl_dir( $tmp->child('syntax'), 'dsl-syntax', "use Langertha::Holmgang;\nsuite 'dsl-syntax' => sub {\n" ), 'suite.pl',
    qr/Missing right curly/, 'a file that does not compile' );
  my $kw    = sums_pl( 'dsl-kw', extra => "title 'again';" );
  my $kwline = 1 + ( () = substr( $kw, 0, index( $kw, "title 'again'" ) ) =~ /\n/g );
  refused( dsl_dir( $tmp->child('kw'), 'dsl-kw', $kw ), 'suite.pl',
    qr/\Atitle: given twice in suite dsl-kw at \S+suite\.pl line $kwline\./, 'a keyword error names the line of suite.pl' );
  refused( dsl_dir( $tmp->child('rule'), 'dsl-rule', sums_pl('dsl-rule') =~ s/equals => 2 \* \$n;/equals => [ 2 * \$n ];/r ),
    'suite.pl: case sum-n1: rules[0].equals', qr/value expected/, 'a structure refusal names suite.pl, the case and the field' );
}

#### each file in a package of its own

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  Langertha::Holmgang::Loader->new->load($dir) for 1 .. 2;
  is_deeply( \@warn, [], 'the same suite.pl twice: no sub redefined' );
  ok( !main->can('helper') && !Langertha::Holmgang::Loader->can('helper'), '... its subs stay in its own package' );
}

#### images relative to the suite directory

{
  my $png = path( $FindBin::Bin, '..', '..', 'share', 'suites', 'demo-sehen', 'img', 'ablauf.png' );
  SKIP: {
    skip 'no share/suites/demo-sehen/img/ablauf.png next to t/', 3 unless -f $png;
    my $code = sums_pl('dsl-img') =~ s/ask 'What is/ask 'Look at the chart. What is/r
      =~ s/(\? Hand it in\.')/$1, images => [ 'chart.png' ]/r;
    my $d = dsl_dir( $tmp->child('img'), 'dsl-img', $code );
    $png->copy( path( $d, 'chart.png' ) );
    my $si = eval { $loader->load($d) };
    ok( $si, 'images on ask load from the suite directory' ) or diag $@;
    my $c = $si && $si->cases->[0];
    ok( $c && $c->has_images, '... the case has the image' );
    isnt( $si && $si->digest, $s->digest, '... and the digest takes it' );
  }
}

#### determinism across processes and hash seeds

{
  my @digests;
  for my $hs ( 0, 1, 12345 ) {
    local $ENV{PERL_HASH_SEED}    = $hs;
    local $ENV{PERL_PERTURB_KEYS} = 2;
    my $lib = path( $FindBin::Bin, '..', '..', 'lib' )->absolute;
    my $pid = IPC::Open3::open3( my $in, my $out, undef, $^X, '-I'.$lib, '-MLangertha::Holmgang::Loader',
      '-e', 'print Langertha::Holmgang::Loader->new->load($ARGV[0])->digest', $dir );
    close $in;
    my $got = do { local $/; <$out> };
    waitpid $pid, 0;
    push @digests, $got;
  }
  is_deeply( \@digests, [ ( $s->digest ) x 3 ], 'the same digest in three processes with different hash seeds' );
}

done_testing;
