#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Dist::Zilla::PluginBundle::Classic;

my $SAMPLE = <<'EOF';
name = Foo
value = bar

[Package / Name]
value = baz
foo = quux

[@Classic]

[PackageTwo / NameTwo]
value = baz
foo = quux
EOF

my $EXPANDED = <<'EOEXPAND';
name = Foo
value = bar

[Package / Name]
value = baz
foo = quux

[GatherDir / Dist::Zilla::PluginBundle::Classic/GatherDir]

[PruneCruft / Dist::Zilla::PluginBundle::Classic/PruneCruft]

[ManifestSkip / Dist::Zilla::PluginBundle::Classic/ManifestSkip]

[MetaYAML / Dist::Zilla::PluginBundle::Classic/MetaYAML]

[License / Dist::Zilla::PluginBundle::Classic/License]

[Readme / Dist::Zilla::PluginBundle::Classic/Readme]

[PkgVersion / Dist::Zilla::PluginBundle::Classic/PkgVersion]

[PodVersion / Dist::Zilla::PluginBundle::Classic/PodVersion]

[PodCoverageTests / Dist::Zilla::PluginBundle::Classic/PodCoverageTests]

[PodSyntaxTests / Dist::Zilla::PluginBundle::Classic/PodSyntaxTests]

[ExtraTests / Dist::Zilla::PluginBundle::Classic/ExtraTests]

[ExecDir / Dist::Zilla::PluginBundle::Classic/ExecDir]

[ShareDir / Dist::Zilla::PluginBundle::Classic/ShareDir]

[MakeMaker / Dist::Zilla::PluginBundle::Classic/MakeMaker]

[Manifest / Dist::Zilla::PluginBundle::Classic/Manifest]

[ConfirmRelease / Dist::Zilla::PluginBundle::Classic/ConfirmRelease]

[UploadToCPAN / Dist::Zilla::PluginBundle::Classic/UploadToCPAN]

[PackageTwo / NameTwo]
value = baz
foo = quux
EOEXPAND

use Dist::Zilla::Util::ExpandINI;

my $out = Dist::Zilla::Util::ExpandINI->filter_string($SAMPLE);

is( $out, $EXPANDED, "Expanding formats as intended" );

done_testing;
