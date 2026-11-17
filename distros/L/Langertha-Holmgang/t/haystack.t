#!/usr/bin/env perl
# Langertha::Holmgang::Haystack, ported from cai-platform t/eval_haystack.t.
# Claims: same spec -> same bytes (also across processes with different
# PERL_HASH_SEED, and the same bytes as cai-platform's Eval::Haystack); the
# size follows the characters -> tokens estimate; inserts stand at their
# position with their neighbours' timestamp; the filler never contains the
# needle patterns (exclude); bad specs are refused with the field path.
# The loader parts of the original (generate in messages and files, digest)
# belong to the loader's tests; the suite parts to the acceptance run.
# Every spec here is invented (ADR 0003).
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal qw( exception );
use Digest::SHA qw( sha256_hex );
use Encode qw( encode );
use File::Spec ();
use FindBin ();

use Langertha::Holmgang::Error;
use Langertha::Holmgang::Haystack;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $CLASS = 'Langertha::Holmgang::Haystack';
my $H     = $CLASS->new;
my $gen   = sub { $H->generate(@_) };

sub refused (&$$) {
  my ( $code, $re, $name ) = @_;
  my $err = exception { $code->() };
  ok( defined $err, $name.': refused' );
  like( $err // '', $re, $name.': reason' );
}

subtest 'every kind: deterministic, size, German' => sub {
  for my $kind ( $CLASS->kinds ) {
    my %s = ( kind => $kind, tokens => 4000, seed => 3 );
    my $a = $gen->( {%s} );
    is( $CLASS->new->generate( {%s} ), $a, $kind.': same spec, same text (fresh instance)' );
    isnt( $gen->( { %s, seed => 4 } ), $a, $kind.': other seed, other text' );
    my $est = $H->estimate_tokens($a);
    cmp_ok( abs( $est - 4000 ), '<', 4000 * 0.05, $kind.': estimated '.$est.' tokens (target 4000)' );
    like( $a, $kind eq 'nginx-access' ? qr{/warenkorb|/bestellung|/artikel/} : qr/[äöüÄÖÜß]/, $kind.': German text' );
    like( $a, qr/\n\z/, $kind.': ends with a newline' );
    unlike( $a, qr/\{(?:ts|host|num|ip|ms|port|pid:[^}]*)\}/, $kind.': no open placeholders' );
    unlike( $a, qr/\0/, $kind.': no marks' );
  }
};

# The digests were taken from cai-platform's CAI::Platform::Eval::Haystack
# (snapshot af7561a5): the same spec gives the same input on both.
subtest 'same bytes as cai-platform' => sub {
  my %sha = (
    journal         => '77c611d5ffe77e8708f6844d93e0a2c14773627def1ad8e48b24006c5a0e00c8',
    syslog          => '7344089e0b5832f4ce549df93da6e633cb197de0e6d2209ea89d42701fa59781',
    'nginx-access'  => '4520315b275987926a8ee98c076a9b1e3ce13c996f04baeadcc2167fb501abe9',
    'postgres-log'  => '23f9b6f388ea29a1ffb133f1fcffb82ceb97aed0b35133b7c7a919b50bea3e47',
    'ini-config'    => '24d09e0f6ea77b1288370bdf0270da1698092fb91c22f9089d8bb70f074f6393',
    'k8s-manifests' => '6787128bc0644d9dd975a535bbf0e252e2ccc0f22c0ff77c0e7a1fd4ccbd7874',
    runbooks        => '144fe0edb2d8afc90f77b49b50d8c70e6315f76220017a0f8b8a71dc9e064fd1',
  );
  is_deeply( [ sort keys %sha ], [ sort $CLASS->kinds ], 'a digest for every kind' );
  is( sha256_hex( encode( 'UTF-8', $gen->( { kind => $_, tokens => 3000, seed => 11 } ) ) ), $sha{$_}, $_ ) for sort keys %sha;
};

subtest 'deterministic across processes and PERL_HASH_SEED' => sub {
  my $lib  = File::Spec->catdir( $FindBin::Bin, File::Spec->updir, 'lib' );
  my $code = <<'PERL';
use strict; use warnings;
use Digest::SHA qw( sha256_hex ); use Encode qw( encode );
use Langertha::Holmgang::Haystack;
my $h = Langertha::Holmgang::Haystack->new;
for my $kind ( $h->kinds ) {
  my $s = { kind => $kind, tokens => 2500, seed => 5, units => [qw( alpha beta gamma )],
    hosts => [qw( n1 n2 n3 n4 )], host => 'n1', exclude => [ 'NADEL-\d+' ],
    insert => [ { at => 0.4, text => '{ts} {host} alpha[{pid:alpha}]: NADEL-{num} {ip}' },
      { from => 0.6, to => 0.8, count => 3, text => 'NADEL-{port} {pid:n1/beta}' } ] };
  print $kind, ' ', sha256_hex( encode( 'UTF-8', $h->generate($s) ) ), "\n";
}
PERL
  my @runs;
  for my $seed ( 1, 2, 977 ) {
    local $ENV{PERL_HASH_SEED}    = $seed;
    local $ENV{PERL_PERTURB_KEYS} = 2;
    open my $fh, '-|', $^X, '-I'.$lib, '-e', $code or die 'cannot run '.$^X.': '.$!;
    push @runs, do { local $/; <$fh> };
    close $fh;
    is( $?, 0, 'PERL_HASH_SEED='.$seed.': child ran' );
  }
  my @lines = split /\n/, $runs[0];
  is( scalar @lines, scalar $CLASS->kinds, 'one digest per kind' );
  is( $runs[1], $runs[0], 'second hash seed: same bytes' );
  is( $runs[2], $runs[0], 'third hash seed: same bytes' );
};

# The block fillers must be consistent in themselves — otherwise the filler
# would be a needle of its own (a wrong Service in the hay).
subtest 'blocks: manifests consistent, runbooks dated' => sub {
  my $k8s  = $gen->( { kind => 'k8s-manifests', tokens => 30000, seed => 9, namespace => 'lager' } );
  my @docs = split /\n---\n/, $k8s;
  my ( %port, %svc, %deploy );
  for my $d (@docs) {
    my ($kind) = $d =~ /^kind: (\S+)$/m or next;
    my ($name) = $d =~ /^  name: (\S+)$/m;
    like( $d, qr/^  namespace: lager$/m, $kind.' '.$name.': namespace' );
    if ( $kind eq 'Deployment' ) {
      ok( !$deploy{$name}++, 'Deployment '.$name.' unique' );
      ( $port{$name} ) = $d =~ /containerPort: (\d+)/;
      like( $d, qr/matchLabels:\n\s+app: \Q$name\E\n[\s\S]*labels:\n\s+app: \Q$name\E/, $name.': selector = labels' );
    }
    elsif ( $kind eq 'Service' ) { ( $svc{$name} ) = $d =~ /targetPort: (\S+)/ }
  }
  cmp_ok( scalar keys %deploy, '>', 20, 'many applications' );
  is_deeply( [ sort keys %svc ], [ sort keys %deploy ], 'a Service per Deployment' );
  is( scalar( grep { $svc{$_} ne 'http' && $svc{$_} ne $port{$_} } keys %svc ), 0, 'every targetPort hits number or name' );

  my $rb = $gen->( { kind => 'runbooks', tokens => 20000, seed => 9 } );
  my @rb = $rb =~ /^## Runbook: .+$/mg;
  cmp_ok( scalar @rb, '>', 20, 'many runbooks' );
  my @stand = $rb =~ /^Seite \d+ · Stand: \d{4}-\d\d-\d\d · /mg;
  is( scalar @stand, scalar @rb, 'each with a date' );
  unlike( $rb, qr/^(\d+\. .+)\n\d+\. \1$/m, 'no step twice in a row' );
};

subtest 'timestamps per kind' => sub {
  my %re = (
    journal        => qr/\AOct 28 22:0\d:\d\d app1 \S+: /,
    syslog         => qr/\A2026-10-28T22:0\d:\d\d\.\d{6}\+01:00 \S+ \S+: /,
    'nginx-access' => qr/\A\d+\.\d+\.\d+\.\d+ - - \[28\/Oct\/2026:22:0\d:\d\d \+0100\] "/,
    'postgres-log' => qr/\A2026-10-28 22:0\d:\d\d\.\d{3} CET \[\d+\] /,
  );
  for my $k ( sort keys %re ) {
    my $t = $gen->( { kind => $k, tokens => 2000, seed => 1, host => 'app1', hosts => ['app1'] } );
    like( $t, $re{$k}, $k.': first line in format' );
    my @l = split /\n/, $t;
    like( $l[-1], qr/(?:Oct 29 05:|2026-10-29T05:|29\/Oct\/2026:05:|2026-10-29 05:)/, $k.': last line at the end of the 8 hours' );
  }
  like( $gen->( { kind => 'syslog', tokens => 1000, tz => 'CEST', start => '2026-06-01 08:00:00', hosts => ['x1'] } ),
    qr/\A2026-06-01T08:0\d:\d\d\.\d{6}\+02:00 x1 /, 'tz and start' );
};

subtest 'inserts: position, placeholders, filler untouched' => sub {
  my %s = ( kind => 'journal', tokens => 6000, seed => 9, host => 'app7', units => [qw( lagerdienst belegimport )],
    exclude => [ 'Zu viele offene Dateien', 'NADEL-\d' ] );
  my $plain = $gen->( {%s} );
  my $with  = $gen->( { %s, insert => [
    { at => 0.5, text => '{ts} {host} lagerdienst[{pid:lagerdienst}]: FEHLER: Zu viele offene Dateien' },
    { from => 0.75, to => 0.875, count => 3, text => '{ts} {host} belegimport[{pid:belegimport}]: NADEL-{num}' },
  ] } );
  my @ins = grep { /Zu viele offene Dateien|NADEL-/ } split /\n/, $with;
  is( scalar @ins, 4, 'four inserted lines' );
  my %pid = map { /^\S+ \S+ \S+ app7 (\w+)\[(\d+)\]/ ? ( $1 => $2 ) : () } split /\n/, $plain;
  like( $ins[0], qr/\AOct 2[89] \d\d:\d\d:\d\d app7 lagerdienst\[$pid{lagerdienst}\]: FEHLER/, 'timestamp, host and PID as in the filler' );
  my ($hh) = $ins[0] =~ /\AOct \d\d (\d\d):/;
  is( $hh, '02', 'at 0.5 of 22:00 + 8 h lies at 02:xx' );
  like( $_, qr/\AOct 29 04:/, 'from/to 0.75-0.875 of 22:00 + 8 h lies at 04:xx' ) for @ins[ 1 .. 3 ];
  like( $_, qr/belegimport\[$pid{belegimport}\]: NADEL-\d+\z/, 'range insert: PID and {num}' ) for @ins[ 1 .. 3 ];
  unlike( $with, qr/\{/, 'all placeholders replaced' );
  my $stripped = join '', map { $_."\n" } grep { !/Zu viele offene Dateien|NADEL-/ } split /\n/, $with;
  is( $stripped, $plain, 'without the inserts exactly the filler' );
  unlike( $plain, qr/$_/, 'filler without /'.$_.'/' ) for @{ $s{exclude} };
  my @lines = split /\n/, $with;
  my $at = ( grep { $lines[$_] =~ /offene Dateien/ } 0 .. $#lines )[0];
  cmp_ok( abs( $at / @lines - 0.5 ), '<', 0.02, 'needle at about half' );
};

subtest 'configuration: blocks, insert at a section boundary' => sub {
  my $t = $gen->( { kind => 'ini-config', tokens => 5000, seed => 2, exclude => ['^\[datenbank\]'],
    insert => [ { at => 0.3, text => "[datenbank]\nmax_verbindungen = 80" } ] } );
  like( $t, qr/\A#/, 'starts with a header comment' );
  like( $t, qr/\n\n\[datenbank\]\nmax_verbindungen = 80\n\n(?:#|\[)/, 'insert as a block of its own' );
  my $n = () = $t =~ /^\[/mg;
  cmp_ok( $n, '>', 20, 'many sections ('.$n.')' );
};

subtest 'checking the spec' => sub {
  refused { $gen->( { kind => 'xml', tokens => 1000 } ) } qr/\Agenerate\.kind: /, 'unknown kind';
  refused { $gen->( { kind => 'journal', tokens => 10 } ) } qr/\Agenerate\.tokens: number 1000\.\.200000/, 'too small';
  refused { $gen->( { kind => 'journal', tokens => 1000, farbe => 1 } ) } qr/\Agenerate\.farbe: unknown key/, 'unknown key';
  refused { $gen->( 'journal' ) } qr/\Agenerate: spec \(hash\)/, 'not a hash';
  refused { $gen->( { kind => 'journal', tokens => 1000, start => 'gestern' } ) } qr/generate\.start/, 'bad start';
  refused { $gen->( { kind => 'journal', tokens => 1000, tz => 'UTC' } ) } qr/generate\.tz/, 'bad tz';
  refused { $gen->( { kind => 'journal', tokens => 1000, units => [] } ) } qr/generate\.units: list of names/, 'empty units';
  refused { $gen->( { kind => 'journal', tokens => 1000, insert => [ { at => 0.5, text => 'x' } ] } ) }
    qr/generate\.exclude: inserts need exclude/, 'insert without exclude';
  refused { $gen->( { kind => 'journal', tokens => 1000, exclude => ['NIRGENDS'], insert => [ { at => 0.5, text => 'x' } ] } ) }
    qr/exclude\[0\].*no insert/, 'exclude matches no insert';
  refused { $gen->( { kind => 'journal', tokens => 1000, exclude => ['x'], insert => [ { at => 1.5, text => 'x' } ] } ) }
    qr/insert\[0\]\.at/, 'at outside 0..1';
  refused { $gen->( { kind => 'journal', tokens => 1000, exclude => ['x'], insert => [ { from => 0.5, to => 0.4, count => 2, text => 'x' } ] } ) }
    qr/insert\[0\]\.to: must lie after from/, 'to before from';
  refused { $gen->( { kind => 'journal', tokens => 1000, exclude => ['('], insert => [ { at => 0.5, text => '(' } ] } ) }
    qr/exclude\[0\]: invalid regular expression/, 'broken regular expression';
  refused { $gen->( { kind => 'journal', tokens => 1000, exclude => ['x'], insert => [ { at => 0.5, text => 'x {pid:fehlt}' } ] } ) }
    qr/insert\[0\]\.text: \{pid:fehlt\}/, 'PID of an unknown service';
  refused { $gen->( { kind => 'journal', tokens => 1000, exclude => ['Oct'] } ) } qr/exclude\[0\]: matches the filler/,
    'exclude matches the filler (timestamps)';
  refused { $gen->( { kind => 'journal', tokens => 1000, exclude => ['.'] } ) } qr/generate\.exclude: excludes almost all/,
    'exclude matches every line';
  refused { $gen->( { kind => 'xml', tokens => 1000 }, 'cases/c.yaml: messages[0].content.generate' ) }
    qr/\Acases\/c\.yaml: messages\[0\]\.content\.generate\.kind: /, 'field prefix given by the caller';
};

subtest 'resolve: parts and cache' => sub {
  my $spec = { kind => 'syslog', tokens => 1500, seed => 5, hosts => [qw( web1 web2 )] };
  my $t = $H->resolve( [ "Vorne\n", { generate => $spec }, 'Hinten' ], 'x' );
  like( $t, qr/\AVorne\n2026-10-28T22:/, 'text before' );
  like( $t, qr/\nHinten\z/, 'text after' );
  is( $H->resolve( { generate => {%$spec} }, 'x' ), $gen->($spec), 'a hash alone' );
  is( $H->resolve( 'nur Text', 'x' ), 'nur Text', 'plain text unchanged' );
  is( $H->resolve( undef, 'x' ), undef, 'undef unchanged' );
  refused { $H->resolve( { generate => $spec, mehr => 1 }, 'm.content' ) } qr/\Am\.content: only generate/, 'only generate';
  refused { $H->resolve( [], 'm.content' ) } qr/\Am\.content: empty list/, 'empty list';
  refused { $H->resolve( [ [] ], 'm.content' ) } qr/\Am\.content\[0\]: part/, 'part not text';
  refused { $H->resolve( [ 'a', { generate => { kind => 'journal', tokens => 5 } } ], 'm.content' ) }
    qr/\Am\.content\[1\]\.generate\.tokens: /, 'field path of a part';
  my $err = Langertha::Holmgang::Error->caught( exception { $H->resolve( [ 'a', [] ], 'm.content' ) } );
  ok( $err, 'a refusal is a Langertha::Holmgang::Error (k29)' );
  is( $err && $err->field, 'm.content[1]', '... its field is the full path' );
  is( $err && $err->reason, 'part: text or generate: { ... }', '... its reason carries no source location' );
  my $first = $gen->($spec);
  is( $gen->($spec), $first, 'cached result is the same text' );
  ok( exists $H->_cache->{ $H->_json->encode($spec) }, 'the spec is cached' );
};

subtest 'estimate_tokens and chars_per_token' => sub {
  is( $CLASS->estimate_tokens( 'x' x 35 ), 10, 'class method: 35 characters are 10 tokens' );
  is( $H->estimate_tokens( 'x' x 36 ), 10, 'instance: rounded' );
  is( $H->estimate_tokens(undef), 0, 'undef is 0' );
  is( $H->estimate_tokens('ä' x 7), 2, 'characters, not bytes' );
  my $three = $CLASS->new( chars_per_token => 3 );
  is( $three->estimate_tokens( 'x' x 30 ), 10, 'own chars_per_token' );
  my $spec = { kind => 'journal', tokens => 2000, seed => 1 };
  isnt( $three->generate($spec), $H->generate($spec), 'chars_per_token changes the text (and so the digest)' );
  cmp_ok( abs( $three->estimate_tokens( $three->generate($spec) ) - 2000 ), '<', 100, '... and the size follows it' );
};

done_testing;
