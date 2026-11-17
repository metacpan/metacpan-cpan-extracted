use strict;
use warnings;
use Test::More;

# Pins the docs: the ABSTRACT line is what MetaCPAN shows,
# so it must not promise forges the plugin does not support, and SetMeta
# must explain itself in a DESCRIPTION.

sub slurp {
  my ($file) = @_;
  open my $fh, '<:encoding(UTF-8)', $file or die "$file: $!";
  local $/;
  return scalar <$fh>;
}

my $codeberg = slurp('lib/Dist/Zilla/Plugin/DBIO/CodebergMeta.pm');
my ($abstract) = $codeberg =~ /^# ABSTRACT: (.*)$/m;
ok defined $abstract, 'CodebergMeta has an ABSTRACT';
unlike $abstract, qr/any git forge/i, 'CodebergMeta ABSTRACT does not claim any git forge';

my $bundle = slurp('lib/Dist/Zilla/PluginBundle/DBIO.pm');
unlike $bundle, qr/Codeberg\/Forgejo or GitHub/, 'bundle comment does not claim GitHub';

my $setmeta = slurp('lib/Dist/Zilla/Plugin/DBIO/SetMeta.pm');
like $setmeta, qr/^=head1 DESCRIPTION$/m, 'SetMeta has a DESCRIPTION';
# Pod::Weaver rewrites "=attr" to "=head2" in the built package; accept both.
like $setmeta, qr/^=(?:attr|head2) author$/m, 'SetMeta documents author';
like $setmeta, qr/^=(?:attr|head2) holder$/m, 'SetMeta documents holder';

{
  # CLAUDE.md is tracked, so it is part of the tarball: always checked.
  my $claude = slurp(q{CLAUDE.md});
  unlike $claude, qr/HeritageLicense/, q{CLAUDE.md no longer lists HeritageLicense};
  for my $plugin (qw(CodebergMeta CoverageGate GatherSkills LicenseFile PodCheckerTest RequireCoreVersion SetMeta VersionLockstepTest)) {
    like $claude, qr/Dist::Zilla::Plugin::DBIO::\Q$plugin\E/, "CLAUDE.md lists $plugin";
  }
}

# --- the coverage gate is described as it behaves ---
{
  # README.md is generated for the tarball and stays out of it, so it is only
  # there in the checkout.
  for my $file (grep { -f } 'README.md', 'lib/Dist/Zilla/PluginBundle/DBIO.pm') {
    my $text = slurp($file);
    unlike $text, qr/xt\/release\/coverage\.t|CoverageTest/,
      "$file does not describe a generated coverage test";
    like $text, qr/aborts under (?:C<|`)?RELEASE=1/,
      "$file says a missing cover_db/ aborts under RELEASE=1";
  }
}

# --- the tarball description names the exclude list the code has ---
for my $file ('CLAUDE.md', 'lib/Dist/Zilla/PluginBundle/DBIO.pm') {
  my $text = slurp($file);
  unlike $text, qr/no exclude list/, "$file does not claim there is no exclude list";
  like $text, qr/exclude_filename/, "$file names the exclude_filename list";
}

# --- no card references in the code, tests, docs or the generated tests ---
{
  require Dist::Zilla::Plugin::DBIO::PodCheckerTest;
  my @sources = (
    ( map { [ $_, slurp($_) ] } grep { -f } 'README.md', 'CLAUDE.md', 'Changes' ),
    ( map { [ $_, slurp($_) ] } glob('lib/Dist/Zilla/*.pm lib/Dist/Zilla/*/*.pm lib/Dist/Zilla/*/*/*.pm lib/Pod/Weaver/*/*.pm lib/Pod/Weaver/*/*/*.pm t/*.t') ),
  );
  for my $src (@sources) {
    my ($name, $text) = @$src;
    unlike $text, qr/\bk[0-9]{1,4}\b|\bkarr k/, "$name carries no card reference";
  }
}

# --- GatherSkills says what holds today ---
unlike slurp('lib/Dist/Zilla/Plugin/DBIO/GatherSkills.pm'), qr/hardlink|symlink/i,
  'GatherSkills does not talk about hardlinks';

done_testing;
