use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.022; # $Config{longdblkind} is available.

if($Config::Config{nvtype} ne '__float128') {

   if($Config::Config{nvtype} eq 'double') {
      warn "Bailing out: NV must be either IEEE 754 long double or __float128";
      exit 0;
   }

   if($Config::Config{nvtype} eq 'long double' &&
      $Config::Config{longdblkind} != 1        &&
      $Config::Config{longdblkind} != 2) {
      warn "Bailing out: NV must be either IEEE 754 long double or __float128";
      exit 0;
  }
}

my %options = %{
{
  NAME => 'Math::Int113',
  VERSION_FROM => 'Int113.pm',
  LICENSE  => 'perl',
  macro => { INSTALLSITELIB => $Config::Config{installsitearch} },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-int113.git',
        web => 'https://github.com/sisyphus/math-int113',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
