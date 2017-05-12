requires "Dist::Zilla" => "5";
requires "Dist::Zilla::Plugin::Bugtracker" => "1.110";
requires "Dist::Zilla::Plugin::CPANFile" => "0";
requires "Dist::Zilla::Plugin::CheckChangesHasContent" => "0";
requires "Dist::Zilla::Plugin::CheckExtraTests" => "0";
requires "Dist::Zilla::Plugin::CheckMetaResources" => "0.001";
requires "Dist::Zilla::Plugin::CheckPrereqsIndexed" => "0.002";
requires "Dist::Zilla::Plugin::ContributorsFromGit" => "0.004";
requires "Dist::Zilla::Plugin::CopyFilesFromBuild" => "0";
requires "Dist::Zilla::Plugin::Git::NextVersion" => "0";
requires "Dist::Zilla::Plugin::GithubMeta" => "0.36";
requires "Dist::Zilla::Plugin::InsertCopyright" => "0.001";
requires "Dist::Zilla::Plugin::MetaNoIndex" => "0";
requires "Dist::Zilla::Plugin::MetaProvides::Package" => "1.14";
requires "Dist::Zilla::Plugin::MinimumPerl" => "0";
requires "Dist::Zilla::Plugin::OurPkgVersion" => "0.004";
requires "Dist::Zilla::Plugin::PodWeaver" => "0";
requires "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "0";
requires "Dist::Zilla::Plugin::TaskWeaver" => "0.101620";
requires "Dist::Zilla::Plugin::Test::CPAN::Changes" => "0";
requires "Dist::Zilla::Plugin::Test::Compile" => "2.036";
requires "Dist::Zilla::Plugin::Test::MinimumVersion" => "2.000003";
requires "Dist::Zilla::Plugin::Test::Perl::Critic" => "0";
requires "Dist::Zilla::Plugin::Test::PodSpelling" => "2.006001";
requires "Dist::Zilla::Plugin::Test::Portability" => "0";
requires "Dist::Zilla::Plugin::Test::ReportPrereqs" => "0.008";
requires "Dist::Zilla::Plugin::Test::Version" => "0";
requires "Dist::Zilla::PluginBundle::Filter" => "0";
requires "Dist::Zilla::PluginBundle::Git" => "1.121010";
requires "Dist::Zilla::Role::PluginBundle::Config::Slicer" => "0";
requires "Dist::Zilla::Role::PluginBundle::Easy" => "0";
requires "Dist::Zilla::Role::PluginBundle::PluginRemover" => "0";
requires "Moose" => "0.99";
requires "Moose::Autobox" => "0";
requires "Pod::Elemental::Transformer::List" => "0.101620";
requires "Pod::Weaver" => "4";
requires "Pod::Weaver::Config::Assembler" => "0";
requires "Pod::Weaver::Plugin::WikiDoc" => "0";
requires "Pod::Weaver::Section::Contributors" => "0.001";
requires "Pod::Weaver::Section::Support" => "1.001";
requires "Test::Portability::Files" => "0.06";
requires "autodie" => "2.00";
requires "namespace::autoclean" => "0.09";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0";
  requires "File::pushd" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "List::Util" => "0";
  requires "Path::Tiny" => "0";
  requires "Test::DZil" => "0";
  requires "Test::More" => "0.96";
  requires "perl" => "5.008001";
  requires "version" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
