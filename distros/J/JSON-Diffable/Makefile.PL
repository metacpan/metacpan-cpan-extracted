use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %build_requires = (
    'Test::More'        => 0.98,
);

my %requires = (
    'strictures'        => 1,
    'JSON::MaybeXS'     => 0,
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5707 };
my $mymeta = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5702 };

WriteMakefile(
  NAME => 'JSON-Diffable',
  VERSION_FROM => 'lib/JSON/Diffable.pm',
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
);
