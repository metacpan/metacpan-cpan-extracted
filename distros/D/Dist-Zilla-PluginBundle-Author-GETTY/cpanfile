requires 'perl', '5.022';

requires 'App::cpanminus', '1.7049';
requires 'CPAN::Meta::Merge', '2.150005';
requires 'Config::Identity', '0.0019';
requires 'Dist::Zilla', '6.040';
requires 'Dist::Zilla::Plugin::Alien', '0.024';
requires 'Dist::Zilla::Plugin::AlienBuild', '0.33';
requires 'Dist::Zilla::Plugin::Authority', '1.009';
requires 'Dist::Zilla::Plugin::Deprecated', '0.007';
requires 'Dist::Zilla::Plugin::Docker::API', '0.107';
requires 'Dist::Zilla::Plugin::GatherAgentContext', '0.002';
requires 'Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch', '0.015';
requires 'Dist::Zilla::Plugin::GitHub::CreateRelease', '0.0012';
requires 'Dist::Zilla::Plugin::GithubMeta', '0.58';
requires 'Dist::Zilla::Plugin::InstallRelease', '0.008';
requires 'Dist::Zilla::Plugin::LicenseFile', '0.002';
requires 'Dist::Zilla::Plugin::MakeMaker::Awesome', '0.49';
requires 'Dist::Zilla::Plugin::MakeMaker::SkipInstall', '1.201';
requires 'Dist::Zilla::Plugin::MetaProvides::Package', '2.004003';
requires 'Dist::Zilla::Plugin::ModuleBuildTiny', '0.020';
requires 'Dist::Zilla::Plugin::PodWeaver', '4.010';
requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile', '0.08';
requires 'Dist::Zilla::Plugin::Repository', '0.25';
requires 'Dist::Zilla::Plugin::Run', '0.050';
requires 'Dist::Zilla::Plugin::TaskWeaver', '0.101629';
requires 'Dist::Zilla::Plugin::Test::ChangesHasContent', '0.011';
requires 'Dist::Zilla::PluginBundle::Git', '2.052';
requires 'Dist::Zilla::PluginBundle::Git::VersionManager', '0.007';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Path::Tiny';
requires 'Pithub', '0.01043';
requires 'Pod::Elemental', '0.103006';
requires 'Pod::Elemental::Transformer::List', '0.102001';
requires 'Pod::Weaver', '4.022';

# Only the local pp check of a binary dist (see the Binaries section); DZIL_BINARY_SKIP=1 skips it.
# 1.031 is the first pp to take the namespace forms of -M (binary_modules = Foo::* goes as -M Foo::**).
recommends 'PAR::Packer', '1.031';

on test => sub {
  # t/binary-scripts.t loads the .github/dzil-binary gate scripts, which use it.
  requires 'Archive::Zip';
  requires 'Module::Runtime';
  requires 'Software::License';
  requires 'Test::More', '1.302226';
};

