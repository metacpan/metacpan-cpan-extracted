#!/usr/bin/env perl
# FILENAME: simple_io.pl
# CREATED: 06/02/14 17:41:09 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test simple INI parsing capacity with bundles without loading them

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

; this comment is ignored
; authordep Example
[@Classic]
;authordep Example
; this comment is ignored

[PackageTwo / NameTwo]
value = baz ; ignored
foo = quux
EOF

my $EXPANDED = <<'EOEXPAND';
name = Foo
value = bar

[Package / Name]
; authordep Example
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
;authordep Example

[PackageTwo / NameTwo]
value = baz
foo = quux
EOEXPAND

use Dist::Zilla::Util::ExpandINI;

my $ct = Dist::Zilla::Util::ExpandINI->new( comments => 'authordeps', );
$ct->_load_string($SAMPLE);
$ct->_expand();
my $ds = $ct->_data;

use Test::Differences qw( eq_or_diff );

#note explain $ds;

is( $ds->[0]->{name}, '_',    '_ section' );
is( $ds->[1]->{name}, 'Name', 'First Package' );
eq_or_diff( $ds->[1]->{lines}, [ 'value', 'baz', 'foo', 'quux' ], 'Values retain order' );
is( $ds->[-1]->{name}, 'NameTwo', 'First Package' );
eq_or_diff( $ds->[-1]->{lines}, [ 'value', 'baz', 'foo', 'quux' ], 'Plugins retain order' );

#note explain $ds;
my $out = $ct->_store_string;

eq_or_diff( $out, $EXPANDED, "Expanding formats as intended" );

done_testing;
