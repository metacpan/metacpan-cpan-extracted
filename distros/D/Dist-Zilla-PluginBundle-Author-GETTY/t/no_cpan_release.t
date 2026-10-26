use strict;
use warnings;
use Test::More;
use Module::Runtime qw(use_module);

use Dist::Zilla::PluginBundle::Author::GETTY;

# Dist::Zilla croaks "you can't release without any Releaser plugins", so a
# no_cpan dist needs one from somewhere.
sub releasers {
  my (%payload) = @_;
  my @plugins = Dist::Zilla::PluginBundle::Author::GETTY->bundle_config({
    name    => '@Author::GETTY',
    package => 'Dist::Zilla::PluginBundle::Author::GETTY',
    payload => \%payload,
  });
  return grep { use_module($_)->does('Dist::Zilla::Role::Releaser') }
         map  { $_->[1] } @plugins;
}

is_deeply [ releasers(no_cpan => 1) ], ['Dist::Zilla::Plugin::FakeRelease'],
  'no_cpan alone gets a FakeRelease so dzil release can run';

is_deeply [ releasers() ], ['Dist::Zilla::Plugin::UploadToCPAN'],
  'a CPAN dist keeps UploadToCPAN and gets no fake';

is_deeply [ releasers(no_cpan => 1, docker_image => 'foo/bar') ],
  ['Dist::Zilla::Plugin::Docker::API'],
  'the default Docker subsection is the Releaser, no fake next to it';

is_deeply [ releasers(no_cpan => 1, run_release => ['deploy.sh %v']) ],
  ['Dist::Zilla::Plugin::Run::Release'],
  'run_release is the Releaser, no fake next to it';

is_deeply [ releasers(no_cpan => 1, docker_image => 'foo/bar', docker_default => 0) ],
  ['Dist::Zilla::Plugin::FakeRelease'],
  'docker_default = 0 leaves the dist without one, so it gets the fake';

done_testing;
