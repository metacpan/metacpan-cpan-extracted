#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88 tests => 10; # done_testing

use Test::DZil 'Builder';

#---------------------------------------------------------------------
sub make_re
{
  my $text = quotemeta shift;

  $text =~ s/\\\n/ *\n/g;

  # Accept either '0' or 0 in prereqs:
  $text =~ s/(\\'0\\')/(?:$1|0)/g;

  qr/^$text/m;
} # end make_re

#---------------------------------------------------------------------
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => <<'END INI',
name     = DZT-Sample
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample
version          = 0.04

[Prereqs]
Foo::Bar = 1.00
Bloofle  = 0

[Prereqs / TestRequires]
Test::More = 0.88

[GatherDir]
[ModuleBuild::Custom]
mb_version = 0.3601
END INI

        'source/Build.PL' => <<'END BUILD',
use Module::Build;

my $builder = My_Build->new(
  module_name        => 'DZT::Sample',
  license            => 'perl',
  dist_author        => 'E. Xavier Ample <example@example.org>',
  dist_version_from  => 'lib/DZT/Sample.pm',
  dynamic_config     => 0,
  # Prerequisites inserted by DistZilla:
##{ $plugin->get_prereqs ##}
);

$builder->create_build_script();
END BUILD
      },
    },
  );

  $tzil->build;

  my $buildPL = $tzil->slurp_file('build/Build.PL');
  #print STDERR $buildPL;

  my $build_requires = <<'END BUILD_REQUIRES';
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
END BUILD_REQUIRES

  my $configure_requires = <<'END CONFIGURE_REQUIRES';
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
END CONFIGURE_REQUIRES

  my $requires = <<'END REQUIRES';
  'requires' => {
    'Bloofle' => '0',
    'Foo::Bar' => '1.00'
  },
END REQUIRES

  like($buildPL, make_re($build_requires),     "build_requires");
  like($buildPL, make_re($configure_requires), "configure_requires");
  like($buildPL, make_re($requires),           "requires");
}

#---------------------------------------------------------------------
sub test_and_build_reqs {
  my $api_version = shift;

  (my $BuildSRC = <<'END BUILD') =~ s/~API_VERSION~/$api_version/;
use Module::Build;

my $builder = My_Build->new(
  module_name        => 'DZT::Sample',
  license            => 'perl',
  dist_author        => 'E. Xavier Ample <example@example.org>',
  dist_version_from  => 'lib/DZT/Sample.pm',
  dynamic_config     => 0,
  # Prerequisites inserted by DistZilla:
##{ $plugin->get_prereqs(~API_VERSION~) ##}
);

$builder->create_build_script();
END BUILD

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => <<'END INI',
name     = DZT-Sample
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample
version          = 0.04

[Prereqs]
Foo::Bar = 1.00
Bloofle  = 0

[Prereqs / TestRequires]
Test::More = 0.88

[Prereqs / BuildRequires]
Foo::Make = 2.00

[GatherDir]
[ModuleBuild::Custom]
mb_version = 0.3601
END INI

        'source/Build.PL' => $BuildSRC,
      },
    },
  );

  $tzil->build;

  my $buildPL = $tzil->slurp_file('build/Build.PL');
  #print STDERR $buildPL;

  my $configure_requires = <<'END CONFIGURE_REQUIRES';
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
END CONFIGURE_REQUIRES

  my $requires = <<'END REQUIRES';
  'requires' => {
    'Bloofle' => '0',
    'Foo::Bar' => '1.00'
  },
END REQUIRES

  like($buildPL, make_re($configure_requires), "configure_requires");
  like($buildPL, make_re($requires),           "requires");

  return $buildPL;
}

#---------------------------------------------------------------------
{
  my $buildPL = test_and_build_reqs(0);

  my $build_requires = <<'END BUILD_REQUIRES_0';
  'build_requires' => {
    'Foo::Make' => '2.00',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
END BUILD_REQUIRES_0

  like($buildPL, make_re($build_requires), "build_requires (api 0)");
}

#---------------------------------------------------------------------
SKIP: {
  my $buildPL = test_and_build_reqs(1);

  eval { Test::DZil->VERSION( 4.300032 ) }
      or skip 'Dist::Zilla 4.300032 required', 2;

  my $build_requires = <<'END BUILD_REQUIRES_1';
  'build_requires' => {
    'Foo::Make' => '2.00',
    'Module::Build' => '0.3601'
  },
END BUILD_REQUIRES_1

  my $test_requires = <<'END TEST_REQUIRES_1';
  'test_requires' => {
    'Test::More' => '0.88'
  },
END TEST_REQUIRES_1

  like($buildPL, make_re($build_requires), "build_requires (api 1)");
  like($buildPL, make_re($test_requires),  "test_requires (api 1)");
}

done_testing;
