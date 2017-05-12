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
[MakeMaker::Custom]
eumm_version = 6.30
END INI

        'source/Makefile.PL' => <<'END MAKEFILE',
use ExtUtils::MakeMaker 6.30;

WriteMakefile(
  NAME           => 'DZT::Sample',
  AUTHOR         => 'E. Xavier Ample <example@example.org>',
  VERSION_FROM   => 'lib/DZT/Sample.pm', # finds $VERSION
##{ $plugin->get_prereqs ##}
##{ $plugin->get_default(qw(LICENSE)) ##}
);
END MAKEFILE
      },
    },
  );

  $tzil->build;

  my $makefilePL = $tzil->slurp_file('build/Makefile.PL');
  #print STDERR $makefilePL;

  my $build_requires = <<'END BUILD_REQUIRES';
  'BUILD_REQUIRES' => {
    'Test::More' => '0.88'
  },
END BUILD_REQUIRES

  my $configure_requires = <<'END CONFIGURE_REQUIRES';
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
END CONFIGURE_REQUIRES

  my $requires = <<'END REQUIRES';
  'PREREQ_PM' => {
    'Bloofle' => '0',
    'Foo::Bar' => '1.00'
  },
END REQUIRES

  like($makefilePL, make_re($build_requires),     "BUILD_REQUIRES");
  like($makefilePL, make_re($configure_requires), "CONFIGURE_REQUIRES");
  like($makefilePL, make_re($requires),           "PREREQ_PM");
}

#---------------------------------------------------------------------
sub test_and_build_reqs {
  my $api_version = shift;

  (my $MakefileSRC = <<'END MAKEFILE') =~ s/~API_VERSION~/$api_version/;
use ExtUtils::MakeMaker 6.63_03;

WriteMakefile(
  NAME           => 'DZT::Sample',
  AUTHOR         => 'E. Xavier Ample <example@example.org>',
  VERSION_FROM   => 'lib/DZT/Sample.pm', # finds $VERSION
##{ $plugin->get_prereqs(~API_VERSION~) ##}
);
END MAKEFILE

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
Foo::Baz = 1.00

[Prereqs / TestRequires]
Test::More = 0.88

[Prereqs / BuildRequires]
Foo::Make = 2.00

[GatherDir]
[MakeMaker::Custom]
eumm_version = 6.63_03
END INI

        'source/Makefile.PL' => $MakefileSRC,
      },
    },
  );

  $tzil->build;

  my $makefilePL = $tzil->slurp_file('build/Makefile.PL');
  #print STDERR $makefilePL;

  my $configure_requires = <<'END CONFIGURE_REQUIRES';
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.63_03'
  },
END CONFIGURE_REQUIRES

  my $requires = <<'END REQUIRES';
  'PREREQ_PM' => {
    'Foo::Baz' => '1.00'
  },
END REQUIRES

  like($makefilePL, make_re($configure_requires), "CONFIGURE_REQUIRES");
  like($makefilePL, make_re($requires),           "PREREQ_PM");

  return $makefilePL;
}

#---------------------------------------------------------------------
{
  my $makefilePL = test_and_build_reqs(0);

  my $build_requires = <<'END BUILD_REQUIRES_0';
  'BUILD_REQUIRES' => {
    'Foo::Make' => '2.00',
    'Test::More' => '0.88'
  },
END BUILD_REQUIRES_0

  like($makefilePL, make_re($build_requires), "BUILD_REQUIRES (api 0)");
}

#---------------------------------------------------------------------
SKIP: {
  my $makefilePL = test_and_build_reqs(1);

  eval { Test::DZil->VERSION( 4.300032 ) }
      or skip 'Dist::Zilla 4.300032 required', 2;

  my $build_requires = <<'END BUILD_REQUIRES';
  'BUILD_REQUIRES' => {
    'Foo::Make' => '2.00'
  },
END BUILD_REQUIRES

  my $test_requires = <<'END TEST_REQUIRES';
  'TEST_REQUIRES' => {
    'Test::More' => '0.88'
  },
END TEST_REQUIRES

  like($makefilePL, make_re($build_requires), "BUILD_REQUIRES (api 1)");
  like($makefilePL, make_re($test_requires),  "TEST_REQUIRES (api 1)");
}

done_testing;
