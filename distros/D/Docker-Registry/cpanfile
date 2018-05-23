requires 'perl' => '5.014001';
requires 'Moose';
requires 'JSON::MaybeXS';
requires 'HTTP::Tiny';
requires 'HTTP::Headers';
requires 'Throwable::Error';
requires 'IO::Socket::SSL';

feature 'gcr-registry', 'Support for GCR' => sub {
  requires 'Crypt::JWT';
  requires 'Path::Class';
};

feature 'ecr-registry', 'Support for ECR' => sub {
  requires 'Paws';
};

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};

on develop => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::VersionFromModule';
  requires 'Dist::Zilla::PluginBundle::Git';
};
