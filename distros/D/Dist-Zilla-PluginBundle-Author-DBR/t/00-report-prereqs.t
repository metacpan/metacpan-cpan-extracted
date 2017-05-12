#!perl

use strict;
use warnings;

use Test::More tests => 1;

use ExtUtils::MakeMaker;
use File::Spec::Functions;
use List::Util qw/max/;

my @modules = qw(
  Carp
  Dist::Zilla
  Dist::Zilla::Plugin::Authority
  Dist::Zilla::Plugin::AutoPrereqs
  Dist::Zilla::Plugin::CheckChangeLog
  Dist::Zilla::Plugin::CheckChangesHasContent
  Dist::Zilla::Plugin::CheckExtraTests
  Dist::Zilla::Plugin::CheckPrereqsIndexed
  Dist::Zilla::Plugin::CheckVersionIncrement
  Dist::Zilla::Plugin::ConfirmRelease
  Dist::Zilla::Plugin::EOLTests
  Dist::Zilla::Plugin::GithubMeta
  Dist::Zilla::Plugin::HasVersionTests
  Dist::Zilla::Plugin::InstallGuide
  Dist::Zilla::Plugin::InstallRelease
  Dist::Zilla::Plugin::MetaJSON
  Dist::Zilla::Plugin::MetaProvides::Class
  Dist::Zilla::Plugin::MetaProvides::Package
  Dist::Zilla::Plugin::MetaTests
  Dist::Zilla::Plugin::MetaYAML
  Dist::Zilla::Plugin::MinimumPerl
  Dist::Zilla::Plugin::ModuleBuild
  Dist::Zilla::Plugin::NextRelease
  Dist::Zilla::Plugin::NoTabsTests
  Dist::Zilla::Plugin::PkgVersion
  Dist::Zilla::Plugin::PodCoverageTests
  Dist::Zilla::Plugin::PodSyntaxTests
  Dist::Zilla::Plugin::PodWeaver
  Dist::Zilla::Plugin::ReadmeFromPod
  Dist::Zilla::Plugin::ReportPhase
  Dist::Zilla::Plugin::ReportVersions
  Dist::Zilla::Plugin::Run::Release
  Dist::Zilla::Plugin::RunExtraTests
  Dist::Zilla::Plugin::SchwartzRatio
  Dist::Zilla::Plugin::ShareDir::Tarball
  Dist::Zilla::Plugin::SpellingCommonMistakesTests
  Dist::Zilla::Plugin::TaskWeaver
  Dist::Zilla::Plugin::Test::CPAN::Changes
  Dist::Zilla::Plugin::Test::ChangesHasContent
  Dist::Zilla::Plugin::Test::CheckDeps
  Dist::Zilla::Plugin::Test::CheckManifest
  Dist::Zilla::Plugin::Test::Compile
  Dist::Zilla::Plugin::Test::Legal
  Dist::Zilla::Plugin::Test::MinimumVersion
  Dist::Zilla::Plugin::Test::Perl::Critic
  Dist::Zilla::Plugin::Test::Portability
  Dist::Zilla::Plugin::Test::ReportPrereqs
  Dist::Zilla::Plugin::Test::UseAllModules
  Dist::Zilla::Plugin::TestRelease
  Dist::Zilla::PluginBundle::Git
  Dist::Zilla::Role::PluginBundle::Merged
  ExtUtils::MakeMaker
  File::Spec::Functions
  List::Util
  Module::Build
  MooseX::Declare
  Pod::Weaver::Plugin::WikiDoc
  Pod::Weaver::Section::Support
  Scalar::Util
  Test::CPAN::Meta
  Test::CheckDeps
  Test::More
  Test::UseAllModules
  perl
  strict
  true
  warnings
);

# replace modules with dynamic results from MYMETA.json if we can
# (hide CPAN::Meta from prereq scanner)
my $cpan_meta = "CPAN::Meta";
if ( -f "MYMETA.json" && eval "require $cpan_meta" ) { ## no critic
  if ( my $meta = eval { CPAN::Meta->load_file("MYMETA.json") } ) {
    my $prereqs = $meta->prereqs;
    delete $prereqs->{develop};
    my %uniq = map {$_ => 1} map { keys %$_ } map { values %$_ } values %$prereqs;
    $uniq{$_} = 1 for @modules; # don't lose any static ones
    @modules = sort keys %uniq;
  }
}

my @reports = [qw/Version Module/];

for my $mod ( @modules ) {
  next if $mod eq 'perl';
  my $file = $mod;
  $file =~ s{::}{/}g;
  $file .= ".pm";
  my ($prefix) = grep { -e catfile($_, $file) } @INC;
  if ( $prefix ) {
    my $ver = MM->parse_version( catfile($prefix, $file) );
    $ver = "undef" unless defined $ver; # Newer MM should do this anyway
    push @reports, [$ver, $mod];
  }
  else {
    push @reports, ["missing", $mod];
  }
}

if ( @reports ) {
  my $vl = max map { length $_->[0] } @reports;
  my $ml = max map { length $_->[1] } @reports;
  splice @reports, 1, 0, ["-" x $vl, "-" x $ml];
  diag "Prerequisite Report:\n", map {sprintf("  %*s %*s\n",$vl,$_->[0],-$ml,$_->[1])} @reports;
}

pass;

# vim: ts=2 sts=2 sw=2 et:
