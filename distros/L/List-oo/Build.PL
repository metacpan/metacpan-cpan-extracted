
use strict;
use warnings;
use Module::Build;
my $build_class;
if(eval {require inc::MoreBuilder}) {
  $build_class = 'inc::MoreBuilder';
}
else {
  $build_class = Module::Build->subclass(code => q(
    sub ACTION_dist {die "you need the inc::MoreBuilder from
      'http://scratchcomputing.com/svn/List-oo/trunk'
      ";
    }
  ));
}

my $builder = $build_class->new(
  module_name         => 'List::oo',
  license             => 'perl',
  requires => {
    'List::Util'      => 0,
    'List::MoreUtils' => 0.21,
    'perl'            => '5.8.1',
  },
  build_requires => {
    'Module::Build'    => 0.26,
    'Test::More'       => 0,
    'Test::NoWarnings' => 0,
  },
  add_to_cleanup      => [ qw(List-oo-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-oo',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/List-oo/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
