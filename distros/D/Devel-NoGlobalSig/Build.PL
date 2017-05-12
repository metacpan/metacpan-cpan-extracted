
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Devel::NoGlobalSig',
  license             => 'perl',
  dist_version_from   => 'lib/Devel/NoGlobalSig.pm',
  requires => {
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Devel-NoGlobalSig-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-NoGlobalSig',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/Devel-NoGlobalSig/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
