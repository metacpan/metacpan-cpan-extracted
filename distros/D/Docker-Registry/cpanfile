requires 'perl' => '5.014001';
requires 'Moose';
requires 'JSON::MaybeXS';
requires 'HTTP::Tiny';
requires 'HTTP::Headers';
requires 'Throwable::Error';
requires 'IO::Socket::SSL';
requires 'MooseX::Types::Moose';

feature 'gcr-registry', 'Support for GCR' => sub {
  requires 'Crypt::JWT';
  requires 'Path::Class';
  requires 'URI';
};

feature 'ecr-registry', 'support for ecr' => sub {
  requires 'Paws';
};

feature 'gitlab-registry', 'support for gitlab' => sub {
};

on test => sub {
  requires 'Test::More';
  requires 'Test::Most';
  requires 'Test::Exception';
  requires 'Sub::Override';
  requires 'Import::Into' => '1.002003';
};

on develop => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::VersionFromModule';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Dist::Zilla::Plugin::CopyFilesFromBuild::Filtered';
};
