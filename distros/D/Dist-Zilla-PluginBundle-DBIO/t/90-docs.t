use strict;
use warnings;
use Test::More;

# Pins the doc fixes of karr k15: the ABSTRACT line is what MetaCPAN shows,
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
  for my $plugin (qw(CodebergMeta CoverageTest GatherSkills LicenseFile PodCheckerTest SetMeta VersionLockstepTest)) {
    like $claude, qr/Dist::Zilla::Plugin::DBIO::\Q$plugin\E/, "CLAUDE.md lists $plugin";
  }
}

done_testing;
