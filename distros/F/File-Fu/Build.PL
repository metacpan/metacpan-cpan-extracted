
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'File::Fu',
  license             => 'perl',
  dist_version_from   => 'lib/File/Fu.pm',
  requires => {
    'IO::File'                => 0, # TODO check version
    'File::Spec'              => 0, # TODO remove
    'File::Which'             => 0.05,
    'Class::Accessor::Classy' => 'v0.9.0',
  },
  build_requires => {
    'Module::Build' => 0.38,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(File-Fu-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://enobacon.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Fu',
      #MailingList => 'mailto:...',
      repository =>
        'git://git.enobacon.com/File-Fu.pm.git',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
