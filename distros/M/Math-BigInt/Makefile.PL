#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

# This is a list of known backend libraries and the version number when these
# libraries became subclasses of Math::BigInt::Lib. New library methods are
# added to Math::BigInt::Lib first. Later, optimized versions are implemented
# for the specific libraries. In the meantime, these new methods won't be
# available to libraries that aren't a subclass of Math::BigInt::Lib.

my $recommend_versions =
  {
   'Math::BigInt::Calc'        => '1.999800',
   'Math::BigInt::FastCalc'    => '0.5000',
   'Math::BigInt::GMP'         => '1.6000',
   'Math::BigInt::Pari'        => '1.3000',
   'Math::BigInt::BitVect'     => '1.13',
   #'Math::BigInt::GMPz'        => '0.001',
  };

my $recommend_update = [];
while (my ($module, $recommend_version) = each %$recommend_versions) {
    next unless eval "require $module";
    my $version = $module -> VERSION();
    next if $version >= $recommend_version;
    push @$recommend_update, [ $module, $recommend_version, $version ];
}

if (@$recommend_update) {
    print <<"EOF";
##########################################################################
#
# Some of the new methods will not work unless the following installed
# modules are updated. It is therefore recommended that the modules listed
# below are upgraded after installing this distribution.
#
# Module                         Recommended    Installed
# ------                         -----------    ---------
EOF
    for my $entry (@$recommend_update) {
        printf "# %-30s %-14s %s\n", @$entry;
    }
    print <<"EOF";
#
##########################################################################

Sleeping for a few seconds ...
EOF
    sleep 5;
}

my %WriteMakefileArgs =
  (
   'NAME'               => 'Math::BigInt',
   'VERSION_FROM'       => 'lib/Math/BigInt.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.006001,


   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Math::Complex'       => 1.39,
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.94,
                           },

   'LICENSE'            => 'perl_5',
   'LIBS'               => [''],        # e.g., '-lm'
   'DEFINE'             => '',          # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',          # e.g., '-I/usr/include/other'
   'SIGN'               => 1,

   'META_MERGE'         => {
       'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pjacklam/p5-Math-BigInt.git',
                web  => 'https://github.com/pjacklam/p5-Math-BigInt',
            },
        },
    },
  );

# Install over the core version? (Cf. CPAN RT #119199 and #119225.)

$WriteMakefileArgs{INSTALLDIRS} = 'perl'
  if $] < 5.012;

WriteMakefile(%WriteMakefileArgs);
