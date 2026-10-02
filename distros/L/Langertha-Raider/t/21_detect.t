use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Detect;

# The detection-rule evaluator of ADR 0012: must / may / must_not clauses of
# file / dir / contains / matches conditions, bounded to the workspace root.

sub workspace {
  my ( %files ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  for my $rel (sort keys %files) {
    my $f = $root->child($rel);
    if ($rel =~ m{/\z}) {
      $f->mkpath;
      next;
    }
    $f->parent->mkpath;
    $f->spew_utf8($files{$rel});
  }
  return $root;
}

sub detect { Langertha::Raider::Detect->new(root => "$_[0]", @_[1 .. $#_]) }

my $PERL = {
  must     => [ { file => 'cpanfile' } ],
  may      => [ { file => 'dist.ini' }, { file => 'Makefile.PL' }, { file => 'lib/**/*.pm' } ],
  must_not => [ { file => '.raider/no-perl' } ],
};

subtest 'the ADR example rule' => sub {
  my $ws = workspace('cpanfile' => "requires 'Moose';\n", 'lib/Foo/Bar.pm' => "package Foo::Bar;\n1;\n");
  my $r = detect($ws)->evaluate($PERL);
  ok($r->{matched}, 'matches with cpanfile and a module under lib/');
  is($r->{reason}, 'must file=cpanfile (cpanfile); must_not file=.raider/no-perl: none; may file=lib/**/*.pm (lib/Foo/Bar.pm)',
    'reason names every deciding condition and what it hit');
  like($r->{checks}, [
    { clause => 'must',     condition => 'file=cpanfile',        held => 1, path => 'cpanfile' },
    { clause => 'must_not', condition => 'file=.raider/no-perl', held => 0 },
    { clause => 'may',      condition => 'file=dist.ini',        held => 0 },
    { clause => 'may',      condition => 'file=Makefile.PL',     held => 0 },
    { clause => 'may',      condition => 'file=lib/**/*.pm',     held => 1, path => 'lib/Foo/Bar.pm' },
  ], 'every evaluated condition is listed');
  is($r->{notes}, [], 'no cap was hit');
};

subtest 'must: every condition holds' => sub {
  my $ws = workspace('dist.ini' => "name = Foo\n");
  my $r = detect($ws)->evaluate($PERL);
  ok(!$r->{matched}, 'no cpanfile, no match');
  is($r->{reason}, 'must file=cpanfile: no match', 'the missing condition is the reason');
  is(scalar @{ $r->{checks} }, 1, 'evaluation stops at the first failed must');
};

subtest 'may: at least one condition holds, when present' => sub {
  my $ws = workspace('cpanfile' => '', 'lib/README' => 'x');
  my $r = detect($ws)->evaluate($PERL);
  ok(!$r->{matched}, 'cpanfile alone does not satisfy may');
  is($r->{reason}, 'may: none of file=dist.ini, file=Makefile.PL, file=lib/**/*.pm held', 'may reason');

  my $only_must = detect($ws)->evaluate({ must => [ { file => 'cpanfile' } ], may => [] });
  ok($only_must->{matched}, 'an empty may list does not constrain');
};

subtest 'must_not: no condition holds' => sub {
  my $ws = workspace('cpanfile' => '', 'dist.ini' => '', '.raider/no-perl' => '');
  my $r = detect($ws)->evaluate($PERL);
  ok(!$r->{matched}, 'opt-out file blocks the match');
  is($r->{reason}, 'must_not file=.raider/no-perl: found .raider/no-perl', 'must_not reason names the hit');

  my $alone = detect(workspace('a' => ''))->evaluate({ must_not => [ { file => 'b' } ] });
  ok($alone->{matched}, 'a rule of only must_not matches when nothing forbidden exists');
};

subtest 'a rule without clauses never matches' => sub {
  my $ws = workspace('cpanfile' => '');
  for my $rule ({}, { must => [], may => [], must_not => [] }) {
    my $r = detect($ws)->evaluate($rule);
    ok(!$r->{matched}, 'no match');
    is($r->{reason}, 'no clauses', 'reason says why');
  }
};

subtest 'file and dir conditions' => sub {
  my $ws = workspace('t/' => undef, 'src/main.rs' => 'fn main() {}', 'Cargo.toml' => '');
  my $d = detect($ws);
  ok($d->evaluate({ must => [ { dir => 't' } ] })->{matched}, 'dir: an existing directory');
  ok(!$d->evaluate({ must => [ { file => 't' } ] })->{matched}, 'file: a directory is not a file');
  ok(!$d->evaluate({ must => [ { dir => 'Cargo.toml' } ] })->{matched}, 'dir: a file is not a directory');
  ok($d->evaluate({ must => [ { file => 'src/*.rs' } ] })->{matched}, 'single-segment wildcard');
  ok($d->evaluate({ must => [ { file => 'Cargo.???l' } ] })->{matched}, '? wildcard');
  ok($d->evaluate({ must => [ { file => './Cargo.toml' } ] })->{matched}, 'leading ./ is ignored');
  ok($d->evaluate({ must => [ { file => 'Cargo.toml', dir => 'src' } ] })->{matched},
    'all keys of one condition hold');
  ok(!$d->evaluate({ must => [ { file => 'Cargo.toml', dir => 'lib' } ] })->{matched},
    'one key of a condition failing fails the condition');
  ok(!$d->evaluate({ must => [ { file => '*.RS' } ] })->{matched}, 'case sensitive, no match at top level');
};

subtest '** matches any depth, including zero' => sub {
  my $ws = workspace('lib/Top.pm' => '', 'deep/a/b/c/d/Deep.pm' => '');
  my $d = detect($ws);
  ok($d->evaluate({ must => [ { file => 'lib/**/*.pm' } ] })->{matched}, 'zero directories between');
  ok($d->evaluate({ must => [ { file => '**/Deep.pm' } ] })->{matched}, 'several directories between');
  ok($d->evaluate({ must => [ { file => 'deep/**' } ] })->{matched}, 'trailing ** matches files below');
  ok(!$d->evaluate({ must => [ { file => 'lib/**/*.t' } ] })->{matched}, 'no false positive');
};

subtest 'wildcards skip dot entries unless the pattern names them' => sub {
  my $ws = workspace('.hidden/Mod.pm' => '', '.env' => '');
  my $d = detect($ws);
  ok(!$d->evaluate({ must => [ { file => '**/*.pm' } ] })->{matched}, '** does not walk dot directories');
  ok(!$d->evaluate({ must => [ { file => '*' } ] })->{matched}, '* does not match a dot file');
  ok($d->evaluate({ must => [ { file => '.env' } ] })->{matched}, 'a literal dot file matches');
  ok($d->evaluate({ must => [ { file => '.*' } ] })->{matched}, 'a pattern starting with . matches dot files');
  ok($d->evaluate({ must => [ { file => '.hidden/*.pm' } ] })->{matched}, 'a literal dot directory is entered');
};

subtest 'contains and matches read the matching file' => sub {
  my $ws = workspace(
    'dist.ini'     => "name = Foo\n[\@Author::GETTY]\n",
    'Makefile.PL'  => "use ExtUtils::MakeMaker;\n",
    'lib/A.pm'     => "package A;\n",
    'lib/B.pm'     => "package B;\nuse Moose;\n",
    'utf8.txt'     => "Grüße\n",
  );
  my $d = detect($ws);
  my $r = $d->evaluate({ must => [ { file => 'dist.ini', contains => '[@Author::GETTY]' } ] });
  ok($r->{matched}, 'contains: literal string, no regex meaning');
  is($r->{reason}, 'must file=dist.ini contains="[@Author::GETTY]" (dist.ini)', 'reason includes the content check');
  ok(!$d->evaluate({ must => [ { file => 'dist.ini', contains => 'Author::ETHER' } ] })->{matched},
    'contains: absent string');
  ok($d->evaluate({ must => [ { file => 'lib/*.pm', contains => 'use Moose' } ] })->{matched},
    'contains: any matching file will do');
  my $m = $d->evaluate({ must => [ { file => 'lib/*.pm', matches => '^use\s+Moose;$' } ] });
  ok($m->{matched}, 'matches: regex, multi-line anchors');
  is($m->{checks}[0]{path}, 'lib/B.pm', 'the file that satisfied it is reported');
  ok(!$d->evaluate({ must => [ { file => 'lib/*.pm', contains => 'package A', matches => 'Moose' } ] })->{matched},
    'contains and matches must hold in the same file');
  ok($d->evaluate({ must => [ { file => 'utf8.txt', contains => 'Grüße' } ] })->{matched}, 'UTF-8 content');
  ok($d->evaluate({ must => [ { file => 'utf8.txt', matches => '^Gr\w+e$' } ] })->{matched}, 'UTF-8 regex');
};

subtest 'content checks read at most 64 KiB' => sub {
  my $big = ('x' x (70 * 1024))."NEEDLE\n";
  my $ws = workspace('big.txt' => $big, 'head.txt' => "NEEDLE\n".('x' x (70 * 1024)));
  my $d = detect($ws);
  my $r = $d->evaluate({ must => [ { file => 'big.txt', contains => 'NEEDLE' } ] });
  ok(!$r->{matched}, 'needle past 64 KiB is not seen');
  like($r->{notes}, [ qr/big\.txt: only the first 65536 bytes were read/ ], 'the cut is reported');
  my $h = $d->evaluate({ must => [ { file => 'head.txt', contains => 'NEEDLE' } ] });
  ok($h->{matched}, 'needle inside the first 64 KiB is found');
  is($h->{notes}, [], 'nothing reported for a condition that held');
};

subtest 'caps: file count and ** depth' => sub {
  my %many = map { ('many/f'.$_.'.txt' => '') } 1 .. 30;
  my $ws = workspace(%many, 'many/zz.pm' => '', 'd/1/2/3/4/5/Deep.pm' => '');
  my $d = detect($ws, max_entries => 10, max_depth => 3);
  my $r = $d->evaluate({ must => [ { file => 'many/*.pm' } ] });
  ok(!$r->{matched}, 'exceeding the entry cap makes the condition false');
  like($r->{notes}, [ qr/must file=many\/\*\.pm: stopped after 10 entries/ ], 'and is reported');
  like($r->{reason}, qr/no match/, 'reason still names the condition');

  my $deep = $d->evaluate({ must => [ { file => 'd/**/Deep.pm' } ] });
  ok(!$deep->{matched}, 'beyond the ** depth cap is not found');
  like($deep->{notes}, [ qr/\*\* depth capped at 3/ ], 'depth cap reported');

  ok(detect($ws, max_depth => 5)->evaluate({ must => [ { file => 'd/**/Deep.pm' } ] })->{matched},
    'found within the cap');
  ok(detect($ws)->evaluate({ must => [ { file => 'many/*.pm' } ] })->{matched}, 'default caps are roomy enough');
};

subtest 'symlinks never lead outside the workspace' => sub {
  my $outside = workspace('secret.pm' => "package Secret;\n", 'dir/inner.pm' => '', 'cpanfile' => 'x');
  my $ws = workspace('lib/Own.pm' => '', 'real/cpanfile' => "requires 'Moose';\n");
  symlink("$outside", $ws->child('escape')) or skip_all 'symlinks not supported';
  symlink($outside->child('secret.pm').'', $ws->child('secret.pm'));
  symlink($outside->child('cpanfile').'', $ws->child('cpanfile'));
  symlink($ws->child('real', 'cpanfile').'', $ws->child('local-link'));
  symlink($ws->child('lib').'', $ws->child('lib-link'));
  my $d = detect($ws);

  my $r = $d->evaluate({ must => [ { file => 'escape/secret.pm' } ] });
  ok(!$r->{matched}, 'a directory symlink out of the root is not entered');
  like($r->{notes}, [ qr/escape: symlink leaves the workspace/ ], 'and reported');
  ok(!$d->evaluate({ must => [ { file => 'secret.pm' } ] })->{matched}, 'a file symlink out of the root does not count');
  ok(!$d->evaluate({ must => [ { file => 'cpanfile', contains => 'x' } ] })->{matched},
    'content of a file outside the root is never read');
  ok(!$d->evaluate({ must => [ { file => '**/inner.pm' } ] })->{matched}, '** does not follow symlinks');
  ok($d->evaluate({ must => [ { file => 'local-link', contains => 'Moose' } ] })->{matched},
    'a symlink inside the root is fine');
  ok($d->evaluate({ must => [ { file => 'lib-link/Own.pm' } ] })->{matched}, 'a literal directory symlink inside the root is entered');
};

subtest 'a missing root matches nothing' => sub {
  my $r = Langertha::Raider::Detect->new(root => '/nonexistent/raider-detect')->evaluate({ must => [ { file => 'x' } ] });
  ok(!$r->{matched}, 'no match, no error');
  my $neg = Langertha::Raider::Detect->new(root => '/nonexistent/raider-detect')->evaluate({ must_not => [ { file => 'x' } ] });
  ok(!$neg->{matched}, 'not even a must_not-only rule');
};

subtest 'validation: bad rules are clear errors' => sub {
  my $class = 'Langertha::Raider::Detect';
  ok(lives { $class->validate_rule($PERL, 'perl') }, 'the ADR rule is valid');
  ok(lives { $class->validate_rule({}, 'empty') }, 'an empty rule is valid (it never matches)');
  my @bad = (
    [ 'not a map',             [],                                            qr/perl: a rule must be a map/ ],
    [ 'unknown clause',        { mustnt => [] },                              qr/perl: unknown key 'mustnt' \(allowed: must, may, must_not\)/ ],
    [ 'clause not a list',     { must => { file => 'x' } },                   qr/perl\.must: must be a list of conditions/ ],
    [ 'condition not a map',   { must => [ 'cpanfile' ] },                    qr/perl\.must\[0\]: a condition must be a map/ ],
    [ 'unknown condition key', { may => [ { fiel => 'x' } ] },               qr/perl\.may\[0\]: unknown key 'fiel' \(allowed: file, dir, contains, matches\)/ ],
    [ 'no file or dir',        { must => [ {} ] },                            qr/perl\.must\[0\]: needs file or dir/ ],
    [ 'contains without file', { must => [ { dir => 'x', contains => 'y' } ] }, qr/perl\.must\[0\]: contains needs file/ ],
    [ 'matches without file',  { must => [ { dir => 'x', matches => 'y' } ] },  qr/perl\.must\[0\]: matches needs file/ ],
    [ 'empty glob',            { must => [ { file => '' } ] },                qr/perl\.must\[0\]: file must be a non-empty string/ ],
    [ 'glob not a string',     { must => [ { file => [ 'x' ] } ] },           qr/perl\.must\[0\]: file must be a non-empty string/ ],
    [ 'absolute glob',         { must => [ { file => '/etc/passwd' } ] },     qr/perl\.must\[0\]: file must be relative to the workspace/ ],
    [ 'parent segment',        { must_not => [ { dir => 'a/../..' } ] },      qr/perl\.must_not\[0\]: dir must not contain '\.\.'/ ],
    [ 'bad regex',             { must => [ { file => 'x', matches => '(' } ] }, qr/perl\.must\[0\]: matches is not a valid regex/ ],
    [ 'empty contains',        { must => [ { file => 'x', contains => '' } ] }, qr/perl\.must\[0\]: contains must be a non-empty string/ ],
  );
  for my $case (@bad) {
    my ( $what, $rule, $re ) = @$case;
    like(dies { $class->validate_rule($rule, 'perl') }, qr/\AInvalid detect rule $re/, $what);
  }
  like(dies { detect(workspace())->evaluate({ must => [ { fiel => 'x' } ] }, 'perl') },
    qr/Invalid detect rule perl\.must\[0\]: unknown key 'fiel'/, 'evaluate validates first');
};

subtest 'describe_condition' => sub {
  my $class = 'Langertha::Raider::Detect';
  is($class->describe_condition({ matches => 'a+', file => 'x', contains => 'y', dir => 'd' }),
    'file=x dir=d contains="y" matches=/a+/', 'fixed key order');
};

done_testing;
