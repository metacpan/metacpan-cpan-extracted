# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.033.
use strict;
use warnings;

# inserted by Dist::Zilla::Plugin::CheckBin 0.008
use Devel::CheckBin;
check_bin('git');

use 5.013002;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "A plugin bundle for distributions built by ETHER",
  "AUTHOR" => "Karen Etheridge <ether\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "Devel::CheckBin" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-Author-ETHER",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.013002",
  "NAME" => "Dist::Zilla::PluginBundle::Author::ETHER",
  "PREREQ_PM" => {
    "CPAN::Changes" => "0.23",
    "CPAN::Meta" => "2.150006",
    "CPAN::Meta::Requirements" => 0,
    "CPAN::Uploader" => 0,
    "Carp" => 0,
    "Devel::CheckBin" => 0,
    "Dist::Zilla" => "5.038",
    "Dist::Zilla::Plugin::Authority" => "1.009",
    "Dist::Zilla::Plugin::AutoMetaResources" => 0,
    "Dist::Zilla::Plugin::AutoPrereqs" => "5.038",
    "Dist::Zilla::Plugin::AutoVersion" => 0,
    "Dist::Zilla::Plugin::CheckIssues" => 0,
    "Dist::Zilla::Plugin::CheckMetaResources" => 0,
    "Dist::Zilla::Plugin::CheckPrereqsIndexed" => "0.019",
    "Dist::Zilla::Plugin::CheckSelfDependency" => 0,
    "Dist::Zilla::Plugin::CheckStrictVersion" => 0,
    "Dist::Zilla::Plugin::ConfirmRelease" => 0,
    "Dist::Zilla::Plugin::CopyFilesFromRelease" => 0,
    "Dist::Zilla::Plugin::EnsureLatestPerl" => 0,
    "Dist::Zilla::Plugin::ExecDir" => 0,
    "Dist::Zilla::Plugin::FileFinder::ByName" => 0,
    "Dist::Zilla::Plugin::GatherDir::Template" => 0,
    "Dist::Zilla::Plugin::GenerateFile::FromShareDir" => 0,
    "Dist::Zilla::Plugin::Git::Check" => 0,
    "Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch" => "0.004",
    "Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts" => "0.008",
    "Dist::Zilla::Plugin::Git::Contributors" => "0.029",
    "Dist::Zilla::Plugin::Git::Describe" => "0.004",
    "Dist::Zilla::Plugin::Git::GatherDir" => "2.016",
    "Dist::Zilla::Plugin::Git::Init" => 0,
    "Dist::Zilla::Plugin::Git::Push" => "2.050",
    "Dist::Zilla::Plugin::Git::PushInitial" => 0,
    "Dist::Zilla::Plugin::Git::Remote::Check" => 0,
    "Dist::Zilla::Plugin::GitHub::Create" => "0.35",
    "Dist::Zilla::Plugin::GitHub::Update" => "0.40",
    "Dist::Zilla::Plugin::GithubMeta" => "0.54",
    "Dist::Zilla::Plugin::InstallGuide" => "1.200005",
    "Dist::Zilla::Plugin::Keywords" => "0.004",
    "Dist::Zilla::Plugin::License" => "5.038",
    "Dist::Zilla::Plugin::MakeMaker" => 0,
    "Dist::Zilla::Plugin::MakeMaker::Fallback" => "0.029",
    "Dist::Zilla::Plugin::Manifest" => 0,
    "Dist::Zilla::Plugin::ManifestSkip" => 0,
    "Dist::Zilla::Plugin::MetaConfig" => 0,
    "Dist::Zilla::Plugin::MetaJSON" => 0,
    "Dist::Zilla::Plugin::MetaNoIndex" => 0,
    "Dist::Zilla::Plugin::MetaProvides::Package" => "1.15000002",
    "Dist::Zilla::Plugin::MetaTests" => 0,
    "Dist::Zilla::Plugin::MetaYAML" => 0,
    "Dist::Zilla::Plugin::MinimumPerl" => "1.006",
    "Dist::Zilla::Plugin::ModuleBuildTiny" => "0.012",
    "Dist::Zilla::Plugin::ModuleBuildTiny::Fallback" => "0.018",
    "Dist::Zilla::Plugin::MojibakeTests" => "0.8",
    "Dist::Zilla::Plugin::PodSyntaxTests" => "5.040",
    "Dist::Zilla::Plugin::PodWeaver" => "4.008",
    "Dist::Zilla::Plugin::Prereqs" => 0,
    "Dist::Zilla::Plugin::Prereqs::AuthorDeps" => "0.006",
    "Dist::Zilla::Plugin::PromptIfStale" => "0.004",
    "Dist::Zilla::Plugin::Readme" => 0,
    "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "0.142180",
    "Dist::Zilla::Plugin::RewriteVersion::Transitional" => "0.006",
    "Dist::Zilla::Plugin::Run::AfterBuild" => "0.041",
    "Dist::Zilla::Plugin::Run::AfterMint" => 0,
    "Dist::Zilla::Plugin::Run::AfterRelease" => "0.038",
    "Dist::Zilla::Plugin::RunExtraTests" => "0.024",
    "Dist::Zilla::Plugin::ShareDir" => 0,
    "Dist::Zilla::Plugin::StaticInstall" => "0.005",
    "Dist::Zilla::Plugin::TemplateModule" => 0,
    "Dist::Zilla::Plugin::Test::CPAN::Changes" => "0.012",
    "Dist::Zilla::Plugin::Test::ChangesHasContent" => 0,
    "Dist::Zilla::Plugin::Test::CleanNamespaces" => "0.006",
    "Dist::Zilla::Plugin::Test::Compile" => "2.039",
    "Dist::Zilla::Plugin::Test::EOL" => "0.17",
    "Dist::Zilla::Plugin::Test::Kwalitee" => "2.10",
    "Dist::Zilla::Plugin::Test::MinimumVersion" => "2.000010",
    "Dist::Zilla::Plugin::Test::NoTabs" => "0.08",
    "Dist::Zilla::Plugin::Test::Pod::Coverage::TrustMe" => 0,
    "Dist::Zilla::Plugin::Test::Pod::No404s" => "1.003",
    "Dist::Zilla::Plugin::Test::PodSpelling" => "2.006003",
    "Dist::Zilla::Plugin::Test::Portability" => "2.000007",
    "Dist::Zilla::Plugin::Test::ReportPrereqs" => "0.022",
    "Dist::Zilla::Plugin::TestRelease" => 0,
    "Dist::Zilla::Plugin::UploadToCPAN" => 0,
    "Dist::Zilla::Plugin::UseUnsafeInc" => 0,
    "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007",
    "Dist::Zilla::Role::MintingProfile" => "5.047",
    "Dist::Zilla::Role::PluginBundle::Config::Slicer" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Dist::Zilla::Role::PluginBundle::PluginRemover" => "0.103",
    "Dist::Zilla::Util" => 0,
    "File::ShareDir" => 0,
    "List::Util" => "1.45",
    "Module::Runtime" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "PadWalker" => 0,
    "Path::Tiny" => "0.062",
    "Pod::Elemental::PerlMunger" => "0.200001",
    "Pod::Elemental::Transformer::List" => "0.102000",
    "Pod::Elemental::Transformer::Verbatim" => 0,
    "Pod::Markdown" => "1.500",
    "Pod::Weaver::Config::Assembler" => 0,
    "Pod::Weaver::Plugin::EnsurePod5" => 0,
    "Pod::Weaver::Plugin::H1Nester" => 0,
    "Pod::Weaver::Plugin::Transformer" => 0,
    "Pod::Weaver::PluginBundle::Default" => "4.000",
    "Pod::Weaver::Section::AllowOverride" => 0,
    "Pod::Weaver::Section::Contributors" => "0.008",
    "Pod::Weaver::Section::GenerateSection" => 0,
    "Pod::Weaver::Section::Legal" => "4.011",
    "Term::ANSIColor" => "2.01",
    "Test::Portability::Files" => "0.07",
    "Test::Spelling" => "0.19",
    "Text::Tabs" => "2013.0426",
    "Try::Tiny" => 0,
    "URI::Escape" => 0,
    "if" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Dist::Zilla::Plugin::MakeMaker" => 0,
    "Dist::Zilla::PluginBundle::Basic" => 0,
    "Dist::Zilla::Role::MetaProvider" => 0,
    "Dist::Zilla::Tester" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::pushd" => 0,
    "JSON::MaybeXS" => 0,
    "Moose::Util" => 0,
    "Path::Tiny" => "0.062",
    "Pod::Weaver::PluginBundle::Default" => "4.000",
    "Term::ANSIColor" => "2.01",
    "Test::DZil" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::File::ShareDir" => 0,
    "Test::More" => "0.96",
    "Test::Needs" => 0,
    "Test::Warnings" => "0.009",
    "lib" => 0,
    "namespace::clean" => 0,
    "parent" => 0
  },
  "VERSION" => "0.167",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CPAN::Changes" => "0.23",
  "CPAN::Meta" => "2.150006",
  "CPAN::Meta::Requirements" => 0,
  "CPAN::Uploader" => 0,
  "Carp" => 0,
  "Devel::CheckBin" => 0,
  "Dist::Zilla" => "5.038",
  "Dist::Zilla::Plugin::Authority" => "1.009",
  "Dist::Zilla::Plugin::AutoMetaResources" => 0,
  "Dist::Zilla::Plugin::AutoPrereqs" => "5.038",
  "Dist::Zilla::Plugin::AutoVersion" => 0,
  "Dist::Zilla::Plugin::CheckIssues" => 0,
  "Dist::Zilla::Plugin::CheckMetaResources" => 0,
  "Dist::Zilla::Plugin::CheckPrereqsIndexed" => "0.019",
  "Dist::Zilla::Plugin::CheckSelfDependency" => 0,
  "Dist::Zilla::Plugin::CheckStrictVersion" => 0,
  "Dist::Zilla::Plugin::ConfirmRelease" => 0,
  "Dist::Zilla::Plugin::CopyFilesFromRelease" => 0,
  "Dist::Zilla::Plugin::EnsureLatestPerl" => 0,
  "Dist::Zilla::Plugin::ExecDir" => 0,
  "Dist::Zilla::Plugin::FileFinder::ByName" => 0,
  "Dist::Zilla::Plugin::GatherDir::Template" => 0,
  "Dist::Zilla::Plugin::GenerateFile::FromShareDir" => 0,
  "Dist::Zilla::Plugin::Git::Check" => 0,
  "Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch" => "0.004",
  "Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts" => "0.008",
  "Dist::Zilla::Plugin::Git::Contributors" => "0.029",
  "Dist::Zilla::Plugin::Git::Describe" => "0.004",
  "Dist::Zilla::Plugin::Git::GatherDir" => "2.016",
  "Dist::Zilla::Plugin::Git::Init" => 0,
  "Dist::Zilla::Plugin::Git::Push" => "2.050",
  "Dist::Zilla::Plugin::Git::PushInitial" => 0,
  "Dist::Zilla::Plugin::Git::Remote::Check" => 0,
  "Dist::Zilla::Plugin::GitHub::Create" => "0.35",
  "Dist::Zilla::Plugin::GitHub::Update" => "0.40",
  "Dist::Zilla::Plugin::GithubMeta" => "0.54",
  "Dist::Zilla::Plugin::InstallGuide" => "1.200005",
  "Dist::Zilla::Plugin::Keywords" => "0.004",
  "Dist::Zilla::Plugin::License" => "5.038",
  "Dist::Zilla::Plugin::MakeMaker" => 0,
  "Dist::Zilla::Plugin::MakeMaker::Fallback" => "0.029",
  "Dist::Zilla::Plugin::Manifest" => 0,
  "Dist::Zilla::Plugin::ManifestSkip" => 0,
  "Dist::Zilla::Plugin::MetaConfig" => 0,
  "Dist::Zilla::Plugin::MetaJSON" => 0,
  "Dist::Zilla::Plugin::MetaNoIndex" => 0,
  "Dist::Zilla::Plugin::MetaProvides::Package" => "1.15000002",
  "Dist::Zilla::Plugin::MetaTests" => 0,
  "Dist::Zilla::Plugin::MetaYAML" => 0,
  "Dist::Zilla::Plugin::MinimumPerl" => "1.006",
  "Dist::Zilla::Plugin::ModuleBuildTiny" => "0.012",
  "Dist::Zilla::Plugin::ModuleBuildTiny::Fallback" => "0.018",
  "Dist::Zilla::Plugin::MojibakeTests" => "0.8",
  "Dist::Zilla::Plugin::PodSyntaxTests" => "5.040",
  "Dist::Zilla::Plugin::PodWeaver" => "4.008",
  "Dist::Zilla::Plugin::Prereqs" => 0,
  "Dist::Zilla::Plugin::Prereqs::AuthorDeps" => "0.006",
  "Dist::Zilla::Plugin::PromptIfStale" => "0.004",
  "Dist::Zilla::Plugin::Readme" => 0,
  "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "0.142180",
  "Dist::Zilla::Plugin::RewriteVersion::Transitional" => "0.006",
  "Dist::Zilla::Plugin::Run::AfterBuild" => "0.041",
  "Dist::Zilla::Plugin::Run::AfterMint" => 0,
  "Dist::Zilla::Plugin::Run::AfterRelease" => "0.038",
  "Dist::Zilla::Plugin::RunExtraTests" => "0.024",
  "Dist::Zilla::Plugin::ShareDir" => 0,
  "Dist::Zilla::Plugin::StaticInstall" => "0.005",
  "Dist::Zilla::Plugin::TemplateModule" => 0,
  "Dist::Zilla::Plugin::Test::CPAN::Changes" => "0.012",
  "Dist::Zilla::Plugin::Test::ChangesHasContent" => 0,
  "Dist::Zilla::Plugin::Test::CleanNamespaces" => "0.006",
  "Dist::Zilla::Plugin::Test::Compile" => "2.039",
  "Dist::Zilla::Plugin::Test::EOL" => "0.17",
  "Dist::Zilla::Plugin::Test::Kwalitee" => "2.10",
  "Dist::Zilla::Plugin::Test::MinimumVersion" => "2.000010",
  "Dist::Zilla::Plugin::Test::NoTabs" => "0.08",
  "Dist::Zilla::Plugin::Test::Pod::Coverage::TrustMe" => 0,
  "Dist::Zilla::Plugin::Test::Pod::No404s" => "1.003",
  "Dist::Zilla::Plugin::Test::PodSpelling" => "2.006003",
  "Dist::Zilla::Plugin::Test::Portability" => "2.000007",
  "Dist::Zilla::Plugin::Test::ReportPrereqs" => "0.022",
  "Dist::Zilla::Plugin::TestRelease" => 0,
  "Dist::Zilla::Plugin::UploadToCPAN" => 0,
  "Dist::Zilla::Plugin::UseUnsafeInc" => 0,
  "Dist::Zilla::PluginBundle::Basic" => 0,
  "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007",
  "Dist::Zilla::Role::MetaProvider" => 0,
  "Dist::Zilla::Role::MintingProfile" => "5.047",
  "Dist::Zilla::Role::PluginBundle::Config::Slicer" => 0,
  "Dist::Zilla::Role::PluginBundle::Easy" => 0,
  "Dist::Zilla::Role::PluginBundle::PluginRemover" => "0.103",
  "Dist::Zilla::Tester" => 0,
  "Dist::Zilla::Util" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::ShareDir" => 0,
  "File::Spec" => 0,
  "File::pushd" => 0,
  "JSON::MaybeXS" => 0,
  "List::Util" => "1.45",
  "Module::Runtime" => 0,
  "Moose" => 0,
  "Moose::Util" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "PadWalker" => 0,
  "Path::Tiny" => "0.062",
  "Pod::Elemental::PerlMunger" => "0.200001",
  "Pod::Elemental::Transformer::List" => "0.102000",
  "Pod::Elemental::Transformer::Verbatim" => 0,
  "Pod::Markdown" => "1.500",
  "Pod::Weaver::Config::Assembler" => 0,
  "Pod::Weaver::Plugin::EnsurePod5" => 0,
  "Pod::Weaver::Plugin::H1Nester" => 0,
  "Pod::Weaver::Plugin::Transformer" => 0,
  "Pod::Weaver::PluginBundle::Default" => "4.000",
  "Pod::Weaver::Section::AllowOverride" => 0,
  "Pod::Weaver::Section::Contributors" => "0.008",
  "Pod::Weaver::Section::GenerateSection" => 0,
  "Pod::Weaver::Section::Legal" => "4.011",
  "Term::ANSIColor" => "2.01",
  "Test::DZil" => 0,
  "Test::Deep" => 0,
  "Test::Fatal" => 0,
  "Test::File::ShareDir" => 0,
  "Test::More" => "0.96",
  "Test::Needs" => 0,
  "Test::Portability::Files" => "0.07",
  "Test::Spelling" => "0.19",
  "Test::Warnings" => "0.009",
  "Text::Tabs" => "2013.0426",
  "Try::Tiny" => 0,
  "URI::Escape" => 0,
  "if" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "namespace::clean" => 0,
  "parent" => 0,
  "strict" => 0,
  "warnings" => 0
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.040
if ($ENV{USER} eq 'ether') {
requires('Dist::Zilla::Plugin::Chrome::ExtraPrompt');
requires('Dist::Zilla::Plugin::BlockRelease');
requires('Dist::Zilla::Plugin::VerifyPhases', '0.015');
}



unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.040
sub _add_prereq {
  my ($mm_key, $module, $version_or_range) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
      and $WriteMakefileArgs{$mm_key}{$module} ne '0'
      and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs (at version $FallbackPrereqs{$module}) -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
        and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub requires { goto &runtime_requires }

sub runtime_requires {
  my ($module, $version_or_range) = @_;
  _add_prereq(PREREQ_PM => $module, $version_or_range);
}
