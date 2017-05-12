use strict;
use warnings;

use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %build_requires = (
    'Test::More'        => 0,
);

my %requires = (
    'Moo'               => 0.009013,
    'File::Path'        => 0,
    'File::Basename'    => 0,
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5707 };
my $mymeta = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5702 };

WriteMakefile(
  NAME => 'File-Tree-Snapshot',
  VERSION_FROM => 'lib/File/Tree/Snapshot.pm',
  PREREQ_PM => {
    %requires,
    ($mymeta_works ? () : (%build_requires)),
  },
  ($mymeta_works
    ? ( # BUILD_REQUIRES makes MYMETA right, requires stops META being wrong
        BUILD_REQUIRES => \%build_requires,
        META_ADD => { requires => \%requires }
      )
    : ( # META_ADD both to get META right - only Makefile written
        META_ADD => {
          requires => \%requires,
          build_requires => \%build_requires,
        }
      )
  ),
  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),
  LICENSE => 'perl',
);;
