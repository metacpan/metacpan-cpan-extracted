#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use Module::CoreList;
use Path::Tiny;
use version;

use Dist::Zilla::PluginBundle::Author::GETTY;
use Dist::Zilla::PluginBundle::Author::GETTY::Docker;
use Pod::Weaver::PluginBundle::Author::GETTY;

# The cpanfile and the code have to agree, both ways, without a network and
# without a real remote (the remotes are fabricated .git/config files):
#
#  1. every plugin and bundle class that configure() puts into the plugin list
#     on a spread of option paths has a cpanfile line of its distribution;
#  2. the same for the Pod::Weaver bundle's packages and the transformers;
#  3. every :version the bundle demands is covered by the pin of that line;
#  4. no runtime requirement without something that loads it;
#  5. a static scan of use / require / extends / with finds nothing in lib/
#     (runtime) or in t/ and .github/dzil-binary/*.pl (on test) that the
#     cpanfile lacks and perl 5.022 does not ship.
#
# The rule: one line per CPAN distribution whose code lib/ loads or hooks in by
# name (plugin, bundle, weaver section or plugin, transformer, a command such as
# cpanm). A module of a distribution that already has a line needs none of its
# own (%SIBLING and @SIBLING_RULES below); the bundle's own Author::GETTY
# modules are exempt; perl's own modules (Module::CoreList, for 5.022, the
# minimum of the cpanfile) are not listed. A class that none of this explains
# turns the test red: add the line, or the entry to %SIBLING.
#
# The cpanfile is read with a plain regex parser (Module::CPANfile is no prereq).

my $ROOT = path(__FILE__)->parent->parent;
my $PERL = 5.022;

# --- the cpanfile ---------------------------------------------------------------

my (%RUN, %TEST, %RECOMMENDS);   # module => version ('' for none)
{
  my $section = 'run';
  for my $line ($ROOT->child('cpanfile')->lines_utf8) {
    next if $line =~ /^\s*#/;
    $section = 'test' if $line =~ /^on\s+test\s*=>/;
    $section = 'run'  if $line =~ /^\};/;
    my ($kind, $mod, $ver) = $line =~ /^\s*(requires|recommends)\s+'([^']+)'(?:\s*,\s*'([^']*)')?/ or next;
    my $into = $kind eq 'recommends' ? \%RECOMMENDS : $section eq 'test' ? \%TEST : \%RUN;
    $into->{$mod} = $ver // '';
  }
}
ok scalar(keys %RUN) > 10 && scalar(keys %TEST) >= 3, 'sanity: the cpanfile parses (runtime and on test requirements)';
my %LISTED = (%RUN, %TEST);

# --- class -> cpanfile line ---------------------------------------------------------

# Modules that have no line of their own because their distribution's line
# covers them. Key: the class, value: the cpanfile module.
my %SIBLING = (
  # shipped in Dist::Zilla itself
  (map { ("Dist::Zilla::Plugin::$_" => 'Dist::Zilla') }
    qw( AutoVersion ConfirmRelease FakeRelease MetaConfig MetaJSON MetaResources NextRelease PkgVersion PodSyntaxTests )),
  'Dist::Zilla::PluginBundle::Basic'  => 'Dist::Zilla',
  'Dist::Zilla::PluginBundle::Filter' => 'Dist::Zilla',
  # Dist-Zilla-Plugin-Git ships these and @Git
  'Dist::Zilla::Plugin::Git::GatherDir' => 'Dist::Zilla::PluginBundle::Git',
  'Dist::Zilla::Plugin::Git::Push'      => 'Dist::Zilla::PluginBundle::Git',
  # Dist-Zilla-Plugin-Run ships all Run::*
  (map { ("Dist::Zilla::Plugin::Run::$_" => 'Dist::Zilla::Plugin::Run') }
    qw( AfterBuild BeforeBuild BeforeRelease Release AfterRelease Test )),
  # Pod-Weaver ships its sections, plugins and the bundle the weaver config expands
  (map { ($_ => 'Pod::Weaver') } qw(
    Pod::Weaver::PluginBundle::CorePrep Pod::Weaver::Plugin::SingleEncoding Pod::Weaver::Plugin::Transformer
    Pod::Weaver::Section::Name Pod::Weaver::Section::Version Pod::Weaver::Section::Region
    Pod::Weaver::Section::Generic Pod::Weaver::Section::Leftovers Pod::Weaver::Section::GenerateSection
    Pod::Weaver::Section::Authors Pod::Weaver::Section::Legal
    Pod::Weaver::Config::Assembler )),
);

# The same for whole families, for the static scan (which sees any package a
# file loads, including the roles and test helpers of Dist::Zilla).
my @SIBLING_RULES = (
  [ qr/\ADist::Zilla::Role::/                        => 'Dist::Zilla' ],
  [ qr/\ADist::Zilla::(?:Tester|Chrome::|Util|Dist::|Stash::|App::)/ => 'Dist::Zilla' ],
  [ qr/\ASoftware::License::/                        => 'Software::License' ],
  [ qr/\APod::Elemental::(?:Document|Element|Transformer|Types)\b/ => 'Pod::Elemental' ],
  [ qr/\APithub::/                                   => 'Pithub' ],
  [ qr/\APod::Weaver::(?:Section|Plugin|PluginBundle|Config)::/ => 'Pod::Weaver' ],
);

# Classes of this bundle itself and its sibling packages: no line.
sub exempt {
  my ($class) = @_;
  return 1 if $class =~ /Author::GETTY/;
  (my $file = "$class.pm") =~ s{::}{/}g;
  return $ROOT->child('lib', $file)->exists;
}

# The cpanfile module that covers a class, or undef.
sub line_for {
  my ($class) = @_;
  return $class if exists $LISTED{$class};
  return $SIBLING{$class} if exists $SIBLING{$class};
  for my $rule (@SIBLING_RULES) {
    return $rule->[1] if $class =~ $rule->[0];
  }
  return;
}

# --- 1. what configure() assembles ---------------------------------------------------

# Collects the nested bundles instead of expanding them (their own
# prerequisites come with their distributions; the bundle's line covers them).
{
  package T::Probe;
  use Moose;
  extends 'Dist::Zilla::PluginBundle::Author::GETTY';
  our @BUNDLES;
  around add_bundle => sub {
    my ($orig, $self, $name, $payload) = @_;
    push @BUNDLES, $name;
    push @BUNDLES, $payload->{'-bundle'} if ref $payload eq 'HASH' && $payload->{'-bundle'};
    return;
  };
}

sub bundle_class {
  my ($name) = @_;
  return $name =~ /\A\@(.+)/ ? "Dist::Zilla::PluginBundle::$1" : "Dist::Zilla::PluginBundle::$name";
}

sub fake_repo {
  my (%remotes) = @_;
  my $dir = tempdir(CLEANUP => 1);
  system('git', 'init', '-q', $dir) == 0 or die "git init $dir failed";
  open my $fh, '>>', "$dir/.git/config" or die "open: $!";
  print $fh "[remote \"$_\"]\n\turl = $remotes{$_}\n\tfetch = +refs/heads/*:refs/remotes/$_/*\n" for sort keys %remotes;
  close $fh;
  return $dir;
}

my $GITHUB   = { origin   => 'git@github.com:getty/some-dist.git' };
my $CODEBERG = { origin   => 'https://codeberg.org/getty/some-dist.git' };
my $GITLAB   = { origin   => 'git@gitlab.com:getty/some-dist.git' };
my $UPSTREAM = { upstream => 'https://gitlab.com/getty/some-dist.git' };
my $NONE     = {};

# [ label, payload, remotes, dies ]
my @PATHS = (
  [ 'default, no remote',        {},                                      $NONE ],
  [ 'github remote',             {},                                      $GITHUB ],
  [ 'codeberg remote',           {},                                      $CODEBERG ],
  [ 'gitlab remote',             {},                                      $GITLAB ],
  [ 'only an upstream',          {},                                      $UPSTREAM ],
  [ 'task',                      { task => 1 },                           $NONE ],
  [ 'task without changes',      { task => 1, no_changes => 1 },          $NONE ],
  [ 'manual_version',            { manual_version => 1 },                 $NONE ],
  [ 'manual_version, finder',    { manual_version => 1, version_finder => [ 'a', 'b' ] }, $NONE ],
  [ 'alien_repo',                { alien_repo => 'http://example.org/r' }, $NONE ],
  [ 'alien_repo, alien_build',   { alien_repo => 'http://example.org/r', alien_build => 1 }, $NONE ],
  [ 'xs',                        { xs => 1 },                             $NONE ],
  [ 'xs_alien',                  { xs_alien => 'Alien::Foo' },            $NONE ],
  [ 'deprecated',                { deprecated => 1 },                     $NONE ],
  [ 'no_install',                { no_install => 1 },                     $NONE ],
  [ 'irc, adoptme',              { irc => 'some-dist', adoptme => 1 },    $NONE ],
  [ 'run_*',                     { map { ("run_$_" => ['true']) } qw( after_build before_build before_release release after_release test ) }, $NONE ],
  [ 'no_cpan',                   { no_cpan => 1 },                        $NONE ],
  [ 'no_podweaver',              { no_podweaver => 1 },                   $NONE ],
  [ 'generate_license',          { generate_license => 1 },               $NONE ],
  [ 'docker_image',              { docker_image => 'registry/app' },      $GITHUB ],
  [ 'binary, github remote',     { binary => [ 'a', 'b' ] },              $GITHUB ],
  [ 'binary, codeberg remote',   { binary => ['a'] },                     $CODEBERG, 'dies' ],
  [ 'binary, gitlab remote',     { binary => ['a'] },                     $GITLAB,   'dies' ],
  [ 'binary, no remote',         { binary => ['a'] },                     $NONE,     'dies' ],
);

my (%CONFIGURED, @DEMANDS, %BUNDLE_SEEN);   # class => paths; [ class, :version, path ]

for my $path (@PATHS) {
  my ($label, $payload, $remotes, $dies) = @$path;
  my $dir  = fake_repo(%$remotes);
  my $orig = getcwd();
  chdir $dir or die "chdir $dir: $!";
  @T::Probe::BUNDLES = ();
  my $bundle = T::Probe->new(name => '@Author::GETTY', payload => $payload);
  my $ok = eval { $bundle->configure; 1 };
  my $err = $@;
  chdir $orig or die "chdir back: $!";   # configure() reads the cwd; it ran inside $dir

  if ($dies) {
    ok !$ok && $err =~ /binary release needs the GitHub release/, "path [$label]: refused, as it has no GitHub release" or diag $err;
    next;
  }
  ok $ok, "path [$label]: configure() runs" or diag $err;
  next unless $ok;
  for my $entry (@{ $bundle->plugins }) {
    my ($name, $class, $conf) = @$entry;
    push @{ $CONFIGURED{$class} }, $label;
    push @DEMANDS, [ $class, $conf->{':version'}, $label ] if ref $conf eq 'HASH' && defined $conf->{':version'};
  }
  push @{ $CONFIGURED{ bundle_class($_) } }, $label for @T::Probe::BUNDLES;
}

# The Docker subsection is a bundle of its own: its plugin list.
{
  my $docker = Dist::Zilla::PluginBundle::Author::GETTY::Docker->new(
    name => '@Author::GETTY::Docker', payload => { image => 'registry/app' });
  $docker->configure;
  push @{ $CONFIGURED{ $_->[1] } }, 'docker subsection' for @{ $docker->plugins };
}

# The paths have to have been walked, or the test checks nothing.
for my $expected (qw(
  Dist::Zilla::Plugin::GithubMeta Dist::Zilla::Plugin::Repository Dist::Zilla::Plugin::Author::GETTY::GiteaMeta Dist::Zilla::Plugin::Author::GETTY::InstallCheck
  Dist::Zilla::Plugin::Alien Dist::Zilla::Plugin::AlienBuild Dist::Zilla::Plugin::MakeMaker::Awesome
  Dist::Zilla::Plugin::MakeMaker::SkipInstall Dist::Zilla::Plugin::ModuleBuildTiny Dist::Zilla::Plugin::Deprecated
  Dist::Zilla::Plugin::TaskWeaver Dist::Zilla::Plugin::AutoVersion Dist::Zilla::Plugin::FakeRelease
  Dist::Zilla::Plugin::MetaResources Dist::Zilla::Plugin::InstallRelease Dist::Zilla::Plugin::Authority
  Dist::Zilla::Plugin::Run::AfterBuild Dist::Zilla::Plugin::Run::Release Dist::Zilla::Plugin::Run::Test
  Dist::Zilla::Plugin::Docker::API Dist::Zilla::Plugin::Author::GETTY::GitHubRelease
  Dist::Zilla::PluginBundle::Git Dist::Zilla::PluginBundle::Git::VersionManager Dist::Zilla::PluginBundle::Filter
  Dist::Zilla::PluginBundle::Basic Dist::Zilla::PluginBundle::Author::GETTY::Binary Dist::Zilla::PluginBundle::Author::GETTY::Docker
)) {
  ok $CONFIGURED{$expected}, "sanity: the option paths reach $expected";
}

# --- 2. the weaver bundle -----------------------------------------------------------

my %WEAVER;
for my $entry (Pod::Weaver::PluginBundle::Author::GETTY->mvp_bundle_config) {
  my ($name, $class, $conf) = @$entry;
  push @{ $WEAVER{$class} }, $name;
  # -Transformer loads Pod::Elemental::Transformer::<transformer>
  push @{ $WEAVER{"Pod::Elemental::Transformer::$conf->{transformer}"} }, $name if $conf->{transformer};
}
ok $WEAVER{'Pod::Elemental::Transformer::List'}, 'sanity: the weaver bundle reaches the List transformer';
ok $WEAVER{'Pod::Weaver::Section::Generic'},     'sanity: ... and the Generic section';

# --- the static scan --------------------------------------------------------------------

# The packages a Perl file loads: use, require, extends, with. POD and comments
# are left out.
sub scan {
  my ($file) = @_;
  my ($code, $pod) = ('', 0);
  for my $line ($file->lines_utf8) {
    if ($line =~ /^=cut\b/) { $pod = 0; next }
    if ($line =~ /^=[a-zA-Z]/) { $pod = 1; next }
    next if $pod || $line =~ /^\s*#/;
    $code .= $line;
  }
  my %found;
  while ($code =~ /(?:^|[;{])[ \t]*(?:use|require)\s+([A-Za-z_]\w*(?:::\w+)*)/mg) {
    my $m = $1;
    $found{$m} = 1 unless $m =~ /\Av\d+\z/;
  }
  while ($code =~ /(?:^|[;{])[ \t]*(?:extends|with)\s+([^;]*);/mg) {
    my $list = $1;
    $found{$1} = 1 while $list =~ /['"]([A-Za-z_]\w*(?:::\w+)*)['"]/g;
  }
  return sort keys %found;
}

sub files_below {
  my ($dir, $re) = @_;
  my @f;
  $dir->visit(sub { push @f, $_ if $_->is_file && $_->basename =~ $re }, { recurse => 1 });
  return sort { "$a" cmp "$b" } @f;
}

my (%LIB_USES, %TEST_USES);   # module => [ files ]
for my $f (files_below($ROOT->child('lib'), qr/\.pm\z/)) {
  push @{ $LIB_USES{$_} }, $f->relative($ROOT)->stringify for scan($f);
}
# Not t/author-*.t and t/release-*.t: dzil generates those in the build
# ([PodSyntaxTests], [Test::ChangesHasContent], ...). Their modules (Test::Pod,
# Test::CPAN::Changes, ...) are develop-phase prereqs the plugins register in
# META, installed by `dzil listdeps --author`; they must never be faked into
# the cpanfile's on-test block.
for my $f (grep({ $_->basename !~ /\A(?:author|release)-/ } files_below($ROOT->child('t'), qr/\.(?:t|pm)\z/)), files_below($ROOT->child('.github', 'dzil-binary'), qr/\.pl\z/)) {
  push @{ $TEST_USES{$_} }, $f->relative($ROOT)->stringify for scan($f);
}
ok scalar(keys %LIB_USES) > 5 && scalar(keys %TEST_USES) > 5, 'sanity: the scan finds modules in lib/ and in t/';
ok $LIB_USES{'Moose'} && $TEST_USES{'Test::More'}, 'sanity: ... Moose in lib/, Test::More in t/';

# --- 1 + 2 + 5: every class has its line ------------------------------------------------

# Returns the line, or '' (and no line) when the class needs none.
sub covered_by_runtime {
  my ($class) = @_;
  my $line = line_for($class);
  return defined $line && exists $RUN{$line} ? $line : undef;
}

my (%NEEDED, %NEEDED_BY_TESTS);   # the lines something in lib/ or configure(), or in the tests, explains
for my $class (sort keys %CONFIGURED) {
  next if exempt($class);
  my $line = covered_by_runtime($class);
  ok defined $line, "configure() class $class has a runtime cpanfile line" . (defined $line ? " ($line)" : '')
    or diag "used on: @{ $CONFIGURED{$class} }; add 'requires' to the cpanfile or an entry to %SIBLING";
  $NEEDED{$line} = 1 if defined $line;
}

for my $class (sort keys %WEAVER) {
  next if exempt($class);
  my $line = covered_by_runtime($class);
  ok defined $line, "weaver bundle package $class has a runtime cpanfile line" . (defined $line ? " ($line)" : '')
    or diag "used by: @{ $WEAVER{$class} }";
  $NEEDED{$line} = 1 if defined $line;
}

for my $mod (sort keys %LIB_USES) {
  $NEEDED{$mod} = 1 if exists $RUN{$mod};   # listed and loaded, even if perl ships it too
  next if exempt($mod) || Module::CoreList->is_core($mod, undef, $PERL);
  my $line = covered_by_runtime($mod);
  ok defined $line, "lib/ loads $mod: runtime cpanfile line" . (defined $line ? " ($line)" : '')
    or diag "loaded in: @{ $LIB_USES{$mod} }";
  $NEEDED{$line} = 1 if defined $line;
}

for my $mod (sort keys %TEST_USES) {
  $NEEDED_BY_TESTS{$mod} = 1 if exists $LISTED{$mod};
  next if exempt($mod) || Module::CoreList->is_core($mod, undef, $PERL);
  my $line = line_for($mod);
  ok defined $line && exists $LISTED{$line}, "the tests load $mod: cpanfile line" . (defined $line ? " ($line)" : '')
    or diag "loaded in: @{ $TEST_USES{$mod} }";
  $NEEDED_BY_TESTS{$line} = 1 if defined $line;
}

# --- 3. the pins ------------------------------------------------------------------------

ok scalar(@DEMANDS) > 0, 'sanity: the bundle demands a :version of some plugin';
for my $d (@DEMANDS) {
  my ($class, $want, $label) = @$d;
  my $line = line_for($class);
  my $pin  = defined $line ? $LISTED{$line} : undef;
  ok defined $pin && length $pin && version->parse($pin) >= version->parse($want),
    "the pin of $class (" . ($line // 'no line') . ' ' . ($pin // 'none') . ") covers the :version $want that [$label] demands";
}

# --- 4. no runtime requirement without a loader ------------------------------------------------

# Requirements that nothing loads by name.
my %NO_LOADER = (
  'perl'          => 'the minimum perl, not a module',
  'CPAN::Meta::Merge' => 'Dist::Zilla merges the x_binaries of several [Author::GETTY::Binary] instances with it; only 2.150005+ merges nested hashes (perl 5.22 ships 2.150001)',
  'App::cpanminus' => 'the default installrelease_command is `cpanm .`: InstallRelease runs it as a command',
);

for my $mod (sort keys %RUN) {
  next if $NO_LOADER{$mod};
  ok $NEEDED{$mod}, "runtime requirement $mod is loaded or hooked in by lib/ or configure()"
    or diag "nothing in lib/, configure() or the weaver bundle needs it; drop it, or give it an entry in %NO_LOADER";
}
for my $mod (sort keys %NO_LOADER) {
  ok exists $RUN{$mod}, "the allowlisted $mod is still a runtime requirement (drop its %NO_LOADER entry otherwise)";
}

# On test: the tests have to load them.
for my $mod (sort keys %TEST) {
  ok $NEEDED_BY_TESTS{$mod}, "on-test requirement $mod is loaded by t/ or .github/dzil-binary/";
}

# A map entry nothing needs any more.
my %ALL_SEEN = (%CONFIGURED, %WEAVER, %LIB_USES, %TEST_USES);
for my $class (sort keys %SIBLING) {
  ok $ALL_SEEN{$class}, "the %SIBLING entry $class is still used somewhere";
}

# Not a runtime need: the optional local pp check.
ok !exists $RUN{'PAR::Packer'} && exists $RECOMMENDS{'PAR::Packer'}, 'PAR::Packer is only recommended';

done_testing;
