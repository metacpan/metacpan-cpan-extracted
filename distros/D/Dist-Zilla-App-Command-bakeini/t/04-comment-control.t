use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Path::Tiny qw( path );
use Dist::Zilla::Util::Test::KENTNL 1.005000 qw( dztest );
use Test::Differences;
use List::Util qw( first );

# ABSTRACT: Test basic expansion

my $test = dztest;
my $ini = simple_ini( ['@Basic'], 'PlaceHolder' );
$ini =~ s{\[PlaceHolder\]}{; authordeps Foo}g;
$test->add_file( 'dist.ini.meta', $ini );

my $result = $test->run_command( [ 'bakeini', '--comments=none' ], );
ok( ref $result, 'self test executed' );
is( $result->error,     undef, 'no errors' );
is( $result->exit_code, 0,     'exit == 0' );

my $source = path( $result->tempdir, 'source', 'dist.ini' );
my (@lines);

ok( $source->exists, 'dist.ini generated' )
  and do {
  @lines = $source->lines_raw( { chomp => 1 } );
  };

sub eq_range {
  my ( $reason, $start, $n, $text ) = @_;
  my @got = splice @lines, $start, $n;
  my @expected = splice @{ [ split /\n/, $text ] }, 0, $n;
  eq_or_diff \@got, \@expected, $reason;
}

sub sort_eq_range {
  my ( $reason, $start, $n, $text ) = @_;
  my @got = sort splice @lines, $start, $n;
  my @expected = sort splice @{ [ split /\n/, $text ] }, 0, $n;
  eq_or_diff \@got, \@expected, $reason;
}

eq_range( "Header in place" => 0, 2, <<'EOF' );
; This file is generated from dist.ini.meta by dzil bakeini.
; Edit that file or the bundles contained within for long-term changes.
EOF

my $first_header = first { $lines[$_] =~ /^\s*[^\s=]+\s*=/ } 0 .. $#lines;

sort_eq_range( "Top Section transfer" => $first_header, 6, <<'EOF' );
abstract = Sample DZ Dist
author = E. Xavier Ample <example@example.org>
license = Perl_5
version = 0.001
name = DZT-Sample
copyright_holder = E. Xavier Ample
EOF

my $first_plugin = first { $lines[$_] =~ /^\[/ } 0 .. $#lines;

eq_range( "Body Expansion" => $first_plugin, 50, <<'EOF' );
[GatherDir / Dist::Zilla::PluginBundle::Basic/GatherDir]

[PruneCruft / Dist::Zilla::PluginBundle::Basic/PruneCruft]

[ManifestSkip / Dist::Zilla::PluginBundle::Basic/ManifestSkip]

[MetaYAML / Dist::Zilla::PluginBundle::Basic/MetaYAML]

[License / Dist::Zilla::PluginBundle::Basic/License]

[Readme / Dist::Zilla::PluginBundle::Basic/Readme]

[ExtraTests / Dist::Zilla::PluginBundle::Basic/ExtraTests]

[ExecDir / Dist::Zilla::PluginBundle::Basic/ExecDir]

[ShareDir / Dist::Zilla::PluginBundle::Basic/ShareDir]

[MakeMaker / Dist::Zilla::PluginBundle::Basic/MakeMaker]

[Manifest / Dist::Zilla::PluginBundle::Basic/Manifest]

[TestRelease / Dist::Zilla::PluginBundle::Basic/TestRelease]

[ConfirmRelease / Dist::Zilla::PluginBundle::Basic/ConfirmRelease]

[UploadToCPAN / Dist::Zilla::PluginBundle::Basic/UploadToCPAN]
EOF

done_testing;

