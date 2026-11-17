#!/usr/bin/env perl
# Excerpts from statute texts under quellen/ (k52), ported from cai-platform
# t/eval_vertragscheck.t (the Auszug block) and t/eval_suite_auszug_digest.t, on
# an invented statute (ADR 0003).
# Claims: a fixture parses into head, provisions and their ranges; an excerpt is
# the fixture's title, range and Stand, then the blocks from the first to the last
# provision named, headings in front included -- byte for byte as cai-platform
# writes it; bad specs and bad fixtures are refused with their field path; the
# file is confined to quellen/ inside the suite (links resolved), as images are;
# expand sets excerpts in and leaves text and generate parts. Through the loader:
# a part (in a list, or alone) is set in before the shape checks and lint; the
# text goes into the digest (a new wording inside the range moves it, a change
# outside every range does not); a refusal names the case file and the field; the
# model is sent the text, never the spec.
use strict;
use warnings;
use utf8;
use Test::More;
use Encode ();
use Path::Tiny qw( path );

use Langertha::Holmgang::Error;
use Langertha::Holmgang::Excerpt;
use Langertha::Holmgang::Loader;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

sub spit {
  my ( $p, $text ) = @_;
  path($p)->parent->mkpath;
  path($p)->spew_raw( Encode::encode( 'UTF-8', $text ) );
}

sub refusal {
  my ( $code ) = @_;
  return eval { $code->(); 1 } ? undef : ( Langertha::Holmgang::Error->caught($@) // $@ );
}

my $STATUTE = "Titel: Leuchtfeuergesetz (LfG)\nStand: erfunden 2026\nLizenz: frei erfunden\n---\n\n"
  . "Abschnitt 1 – Allgemeines\n\n§ 1 Zweck\nDieses Gesetz regelt Leuchtfeuer.\n\n§ 2 Begriffe\n(1) Ein Feuer brennt.\n(2) Ein Turm steht.\n\n"
  . "Abschnitt 2 – Pflichten\n\nTitel 1 – Wache\n\n§ 3 Wache\nJedes Feuer ist zu bewachen.\n\n§ 3a (weggefallen)\n\n§ 4 Schluss\nEnde.\n";

subtest 'the module' => sub {
  my $tmp = Path::Tiny->tempdir;
  spit( "$tmp/quellen/lfg.txt", $STATUTE );
  my $ex = Langertha::Holmgang::Excerpt->new;
  my $q  = $ex->source( "$tmp", 'quellen/lfg.txt', 'f' );
  is_deeply( [ map { $_->{label} } @{ $q->{norms} } ], [ '§ 1', '§ 2', '§ 3', '§ 3a', '§ 4' ], 'the provisions of the fixture' );
  is( $q->{head}{Stand}, 'erfunden 2026', 'head lines' );
  is( $q->{norms}[2]{title}, '§ 3 Wache', 'a provision\'s title is its first line' );
  is( $ex->text( { datei => 'quellen/lfg.txt', von => '§ 3', bis => '§ 3a' }, 'f', "$tmp" ),
    "Leuchtfeuergesetz (LfG)\nAuszug: § 3 bis § 3a\nStand: erfunden 2026\n\nAbschnitt 2 – Pflichten\n\nTitel 1 – Wache\n\n§ 3 Wache\nJedes Feuer ist zu bewachen.\n\n§ 3a (weggefallen)\n",
    'the range with the headings in front, without § 4' );
  is( $ex->text( { datei => 'quellen/lfg.txt', von => '§ 4', bis => '§ 4' }, 'f', "$tmp" ),
    "Leuchtfeuergesetz (LfG)\nAuszug: § 4 bis § 4\nStand: erfunden 2026\n\n§ 4 Schluss\nEnde.\n", 'one provision' );

  my @bad = (
    [ { datei => '../x.txt', von => '§ 1', bis => '§ 2' },              'f.datei', qr{quellen/<name>\.txt} ],
    [ { datei => 'quellen/../lfg.txt', von => '§ 1', bis => '§ 2' },    'f.datei', qr{quellen/<name>\.txt} ],
    [ { datei => 'quellen/LfG.txt', von => '§ 1', bis => '§ 2' },       'f.datei', qr{quellen/<name>\.txt} ],
    [ { datei => 'quellen/fehlt.txt', von => '§ 1', bis => '§ 2' },     'f.datei', qr/missing/ ],
    [ { datei => 'quellen/lfg.txt', von => '§ 9', bis => '§ 2' },       'f.von',   qr/§ 9 is not in quellen\/lfg\.txt/ ],
    [ { datei => 'quellen/lfg.txt', von => '§ 1', bis => [] },          'f.bis',   qr/label of a provision/ ],
    [ { datei => 'quellen/lfg.txt', von => '§ 3', bis => '§ 1' },       'f.bis',   qr/§ 1 comes before § 3/ ],
    [ { datei => 'quellen/lfg.txt', von => '§ 1', bis => '§ 2', tokens => 5 }, 'f.tokens', qr/unknown key/ ],
    [ 'quellen/lfg.txt',                                               'f',       qr/\{ datei, von, bis \} expected/ ],
  );
  for my $b (@bad) {
    my $e = refusal( sub { $ex->text( $b->[0], 'f', "$tmp" ) } );
    ok( ref $e && $e->field eq $b->[1] && $e->reason =~ $b->[2], "refused: $b->[1] ($b->[2])" ) or diag( $e // 'not refused' );
  }
  my $e = refusal( sub { $ex->text( { datei => 'quellen/lfg.txt', von => '§ 1', bis => '§ 1' }, 'f', undef ) } );
  ok( ref $e && $e->field eq 'f.datei' && $e->reason =~ /suite directory/, 'refused: no suite directory' );

  my $x = $ex->expand( [ 'vor ', { auszug => { datei => 'quellen/lfg.txt', von => '§ 4', bis => '§ 4' } }, { generate => { kind => 'journal' } } ], 'f', "$tmp" );
  like( $x->[1], qr/\ALeuchtfeuergesetz.*§ 4 Schluss/s, 'expand sets the excerpt in' );
  is( $x->[0], 'vor ', '... text stays' );
  is_deeply( $x->[2], { generate => { kind => 'journal' } }, '... generate stays for the haystack' );
  my $one = $ex->expand( { auszug => { datei => 'quellen/lfg.txt', von => '§ 4', bis => '§ 4' } }, 'f', "$tmp" );
  is( ref $one, 'ARRAY', 'a single excerpt becomes a list of one part' );
  is( $ex->expand( 'plain', 'f', "$tmp" ), 'plain', 'a text is left alone' );
  $e = refusal( sub { $ex->expand( [ { auszug => { datei => 'quellen/lfg.txt', von => '§ 4', bis => '§ 4' }, x => 1 } ], 'f', "$tmp" ) } );
  ok( ref $e && $e->field eq 'f[0]' && $e->reason =~ /alone/, 'refused: auszug with another key' );
  is_deeply( [ $ex->files( [ 'a', { auszug => { datei => 'quellen/a.txt' } }, { generate => {} }, { auszug => { datei => 'quellen/b.txt' } } ] ) ],
    [ 'quellen/a.txt', 'quellen/b.txt' ], 'files: the fixtures a content names' );
};

subtest 'fixtures that do not hold' => sub {
  my $tmp = Path::Tiny->tempdir;
  my $ex  = Langertha::Holmgang::Excerpt->new;
  my %bad = (
    'no head separator'  => [ "§ 1 A\nx\n",                                   qr/'---' missing/ ],
    'head without colon' => [ "Titel x\n---\n\n§ 1 A\nx\n",                   qr/head line without a colon/ ],
    'twice'              => [ "Titel: x\n---\n\n§ 1 A\nx\n\n§ 1 B\ny\n",      qr/provision § 1 twice/ ],
    'no final newline'   => [ "Titel: x\n---\n\n§ 1 A\nx",                    qr/is no block/ ],
  );
  for my $name ( sort keys %bad ) {
    spit( "$tmp/quellen/x.txt", $bad{$name}[0] );
    my $e = refusal( sub { $ex->source( "$tmp", 'quellen/x.txt', 'f.datei' ) } );
    ok( ref $e && $e->field eq 'f.datei' && $e->reason =~ $bad{$name}[1], "refused: $name" ) or diag( $e // 'not refused' );
  }
  path("$tmp/quellen/x.txt")->spew_raw("Titel: \xFF\n---\n\n\xA7 1 A\nx\n");
  my $e = refusal( sub { $ex->source( "$tmp", 'quellen/x.txt', 'f.datei' ) } );
  ok( ref $e && $e->reason =~ /not UTF-8/, 'refused: not UTF-8' );
  spit( "$tmp/quellen/x.txt", "Titel: x\n---\n\n§ 1 A\nx\n" );
  is( scalar @{ $ex->source( "$tmp", 'quellen/x.txt', 'f' )->{norms} }, 1, '... the mended file is read anew' );
};

subtest 'confinement, as for images' => sub {
  my $tmp   = Path::Tiny->tempdir;
  my $suite = path( $tmp, 'suite' );
  spit( "$tmp/outside.txt", $STATUTE );
  spit( "$suite/quellen/inside.txt", $STATUTE );
  my $ex = Langertha::Holmgang::Excerpt->new;
  SKIP: {
    skip 'no symlinks here', 3 unless eval { symlink( "$tmp/outside.txt", "$suite/quellen/link.txt" ) };
    my $e = refusal( sub { $ex->source( "$suite", 'quellen/link.txt', 'f' ) } );
    ok( ref $e && $e->reason =~ /outside the suite directory/, 'a link out of the suite is refused' );
    symlink( "$suite/quellen/inside.txt", "$suite/quellen/in-link.txt" ) or die $!;
    ok( $ex->source( "$suite", 'quellen/in-link.txt', 'f' ), 'a link inside the suite is fine' );
    path("$suite/quellen/dir.txt")->mkpath;
    $e = refusal( sub { $ex->source( "$suite", 'quellen/dir.txt', 'f' ) } );
    ok( ref $e && $e->reason =~ /not a plain file/, 'a directory is refused' );
  }
};

# --- through the loader ----------------------------------------------------------

my $tmp = Path::Tiny->tempdir;
my $dir = "$tmp/auszug";
spit( "$dir/suite.yaml", <<'Y' );
format: 2
id: auszug
version: 1
title: Excerpt
topic: probe
tools:
  - name: answer
    description: Give the answer.
    parameters: { type: object, required: [verdict], properties: { verdict: { type: string, enum: [ja, nein] } } }
    handlers:
      - apply: [ { set: answer, value: '{verdict}' } ]
        output: ok
Y
my $case = sub {
  my ( $content ) = @_;
  spit( "$dir/cases/c1.yaml", <<"Y" );
id: c1
title: Clause
messages:
  - role: user
    content:
$content
state: { answer: nein }
rules: [ { title: answered, state: answer, equals: ja } ]
solution: [ { tool: answer, args: { verdict: ja } } ]
alternatives: [ { title: twice, calls: [ { tool: answer, args: { verdict: ja } }, { tool: answer, args: { verdict: ja } } ] } ]
wrong_solutions: [ { title: wrong, calls: [ { tool: answer, args: { verdict: nein } } ] } ]
Y
};
my $list   = qq{      - "Check the clause against the text.\\n"\n      - auszug: { datei: quellen/gesetz.txt, von: § 2, bis: § 3 }};
my $single = qq{      auszug: { datei: quellen/gesetz.txt, von: § 2, bis: § 3 }};

my $statute = sub {
  my ( %o ) = @_;
  my $s2 = $o{s2} // 'Ein Feuer brennt nachts.';
  my $s9 = $o{s9} // 'Schlussvorschrift.';
  spit( "$dir/quellen/gesetz.txt", "Titel: Leuchtfeuergesetz\nStand: 2026\n---\n\n§ 1 Anwendung\nGilt für Feuer.\n\n§ 2 Zeit\n$s2\n\n§ 3 Frist\nZwei Wochen.\n\n§ 9 Ende\n$s9\n" );
};

my $L = Langertha::Holmgang::Loader->new;
for my $form ( [ list => $list ], [ 'a single part' => $single ] ) {
  my ( $name, $content ) = @$form;
  $case->($content);
  $statute->();
  my $s1 = $L->load($dir);
  my $sent = $s1->cases->[0]->prompt_messages->[0]{content};
  like( $sent, qr/Ein Feuer brennt nachts\./, "$name: excerpt set in" );
  ok( !ref $sent && $sent !~ /auszug:|datei/, "$name: the model is sent text, not the spec" );
  is( ref $s1->cases->[0]->messages->[0]{content}, $name eq 'list' ? 'ARRAY' : 'HASH', "$name: the case keeps the message as written" );

  $statute->( s2 => 'Ein Feuer brennt immer.' );
  my $s2 = $L->load($dir);
  like( $s2->cases->[0]->prompt_messages->[0]{content}, qr/brennt immer/, '... new wording set in' );
  isnt( $s2->digest, $s1->digest, '... new wording inside the range: another digest' );

  $statute->( s2 => 'Ein Feuer brennt immer.', s9 => 'Geänderte Schlussvorschrift.' );
  my $s3 = $L->load($dir);
  is( $s3->cases->[0]->prompt_messages->[0]{content}, $s2->cases->[0]->prompt_messages->[0]{content}, '... changed outside: the same excerpt' );
  is( $s3->digest, $s2->digest, '... the same digest' );
}

$case->(qq{      - "x"\n      - auszug: { datei: quellen/gesetz.txt, von: § 2, bis: § 7 }});
my $e = refusal( sub { $L->load($dir) } );
ok( ref $e && $e->field eq 'cases/c1.yaml: messages[0].content[1].auszug.bis' && $e->reason =~ /§ 7 is not in/,
  'a refusal names the case file and the field' ) or diag( $e // 'loaded' );
$case->(qq{      - "x"\n      - auszug: { datei: quellen/../suite.yaml, von: § 2, bis: § 3 }});
$e = refusal( sub { $L->load($dir) } );
ok( ref $e && $e->field eq 'cases/c1.yaml: messages[0].content[1].auszug.datei', 'a path out of quellen/ is refused' ) or diag( $e // 'loaded' );

done_testing;
