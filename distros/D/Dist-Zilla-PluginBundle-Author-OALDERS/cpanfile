requires "Code::TidyAll::Plugin::SortLines::Naturally" => "0.000003";
requires "Code::TidyAll::Plugin::UniqueLines" => "0.000003";
requires "Dist::Zilla::Plugin::AutoPrereqs" => "0";
requires "Dist::Zilla::Plugin::CPANFile" => "0";
requires "Dist::Zilla::Plugin::CheckChangesHasContent" => "0";
requires "Dist::Zilla::Plugin::ConfirmRelease" => "0";
requires "Dist::Zilla::Plugin::ContributorsFile" => "0";
requires "Dist::Zilla::Plugin::CopyFilesFromBuild" => "0";
requires "Dist::Zilla::Plugin::CopyFilesFromRelease" => "0";
requires "Dist::Zilla::Plugin::ExecDir" => "0";
requires "Dist::Zilla::Plugin::Git::Check" => "0";
requires "Dist::Zilla::Plugin::Git::Commit" => "0";
requires "Dist::Zilla::Plugin::Git::Contributors" => "0";
requires "Dist::Zilla::Plugin::Git::GatherDir" => "0";
requires "Dist::Zilla::Plugin::Git::Push" => "0";
requires "Dist::Zilla::Plugin::Git::Tag" => "0";
requires "Dist::Zilla::Plugin::GithubMeta" => "0";
requires "Dist::Zilla::Plugin::InstallGuide" => "0";
requires "Dist::Zilla::Plugin::License" => "0";
requires "Dist::Zilla::Plugin::MAXMIND::TidyAll" => "0";
requires "Dist::Zilla::Plugin::MakeMaker" => "0";
requires "Dist::Zilla::Plugin::Manifest" => "0";
requires "Dist::Zilla::Plugin::ManifestSkip" => "0";
requires "Dist::Zilla::Plugin::MetaConfig" => "0";
requires "Dist::Zilla::Plugin::MetaJSON" => "0";
requires "Dist::Zilla::Plugin::MetaNoIndex" => "0";
requires "Dist::Zilla::Plugin::MetaResources" => "0";
requires "Dist::Zilla::Plugin::MetaYAML" => "0";
requires "Dist::Zilla::Plugin::MinimumPerl" => "0";
requires "Dist::Zilla::Plugin::PodCoverageTests" => "0";
requires "Dist::Zilla::Plugin::PodWeaver" => "0";
requires "Dist::Zilla::Plugin::Prereqs" => "0";
requires "Dist::Zilla::Plugin::PromptIfStale" => "0";
requires "Dist::Zilla::Plugin::PruneCruft" => "0";
requires "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "0";
requires "Dist::Zilla::Plugin::RunExtraTests" => "0";
requires "Dist::Zilla::Plugin::ShareDir" => "0";
requires "Dist::Zilla::Plugin::Test::CPAN::Changes" => "0";
requires "Dist::Zilla::Plugin::Test::PodSpelling" => "0";
requires "Dist::Zilla::Plugin::Test::ReportPrereqs" => "0";
requires "Dist::Zilla::Plugin::Test::Synopsis" => "0";
requires "Dist::Zilla::Plugin::Test::TidyAll" => "0";
requires "Dist::Zilla::Plugin::TestRelease" => "0";
requires "Dist::Zilla::Plugin::TravisCI::StatusBadge" => "0";
requires "Dist::Zilla::Plugin::UploadToCPAN" => "0";
requires "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.002";
requires "Dist::Zilla::Role::PluginBundle::Config::Slicer" => "0";
requires "Dist::Zilla::Role::PluginBundle::Easy" => "0";
requires "Dist::Zilla::Role::PluginBundle::PluginRemover" => "0";
requires "List::AllUtils" => "0";
requires "Moose" => "0";
requires "Perl::Tidy" => "2018220";
requires "Pod::Elemental::Transformer::List" => "0";
requires "Test::Code::TidyAll" => "0.70";
requires "Types::Path::Tiny" => "0";
requires "Types::Standard" => "0";
requires "feature" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "perl" => "5.010";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.010";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.96";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007";
};
