requires 'perl', 'v5.14.0'; # for kwalitee

requires 'Moose';
requires 'version';
requires 'namespace::autoclean';

requires 'Dist::Zilla';
requires 'Dist::Zilla::Role::PluginBundle::Easy';

requires 'Git::Wrapper';
requires 'Dist::Zilla::Role::LicenseProvider';

requires 'Dist::Zilla::Plugin::Test::Compile';
requires 'Dist::Zilla::Plugin::Test::ReportPrereqs';

requires 'Dist::Zilla::Plugin::StaticInstall';

requires 'Dist::Zilla::Plugin::OurPkgVersion';
requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
requires 'Dist::Zilla::Plugin::ReadmeAnyFromPod';
requires 'Dist::Zilla::Plugin::MetaProvides::Package';

requires 'Dist::Zilla::Plugin::GitHub::Meta', '0.46';
requires 'Dist::Zilla::Plugin::GitHub::UploadRelease';

requires 'Dist::Zilla::Plugin::Git::NextVersion';
requires 'Dist::Zilla::Plugin::Git::Commit';
requires 'Dist::Zilla::Plugin::Git::Tag';
requires 'Dist::Zilla::Plugin::Git::Push';

requires 'Dist::Zilla::Plugin::ChangelogFromGit';

requires 'Dist::Zilla::Plugin::Git::Contributors';
requires 'Dist::Zilla::Plugin::PodWeaver';
requires 'Pod::Weaver::Section::Contributors';

on test => sub {
    requires 'Test::DZil';
    requires 'Test::Deep';
    requires 'File::Temp';
    requires 'File::pushd';
    requires 'Test::Pod', '1.14';
    requires 'Test::Strict';
};

on develop => sub {
    requires 'Dist::Zilla::Plugin::Bootstrap::lib';
};
