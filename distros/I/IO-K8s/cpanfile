requires 'Moose';
requires 'JSON::MaybeXS';
requires 'Module::Runtime';

on 'test' => sub {
  requires 'Test::More';
};

on 'develop' => sub {
  requires 'Swagger::Schema';
  requires 'Throwable::Error';

  requires 'Template';
  requires 'Path::Class';

  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::VersionFromModule';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Dist::Zilla::Plugin::UploadToCPAN';
  requires 'Dist::Zilla::Plugin::RunExtraTests';
  requires 'Dist::Zilla::Plugin::Test::Compile';
};
