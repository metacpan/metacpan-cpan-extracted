
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'JSON::ON',
  license             => 'perl',
  requires => {
    'JSON'                    => 0, # JSON::XS if you like
    'Scalar::Util'            => 0,
    'Class::Accessor::Classy' => 0,
  },
  build_requires => {
    'Module::Build' => 0.34,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(JSON-ON-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://enobacon.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-ON',
      #MailingList => 'mailto:...',
      repository =>
        'git://git.scratchcomputing.com/JSON-ON.pm.git',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
