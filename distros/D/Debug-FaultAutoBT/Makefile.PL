use ExtUtils::MakeMaker;

my %prereq = (
    File::Spec => '0.82',
);

WriteMakefile(
    NAME		=> 'Debug::FaultAutoBT',
    VERSION_FROM	=> 'FaultAutoBT.pm',
    PREREQ_PM		=> \%prereq,
    DEFINE		=> '-Wall -O0 -g',
    OBJECT              => q/$(O_FILES)/,
    ($] >= 5.005 ?
     (ABSTRACT_FROM => 'FaultAutoBT.pm',
      AUTHOR        => 'Stas Bekman <stas@stason.org>') : ()),
    dist => {
              PREOP        => 'pod2text FaultAutoBT.pm > $(DISTVNAME)/README',
              COMPRESS     => 'gzip -9f',
              SUFFIX       => '.gz',
              ZIP          => 'zip',
              ZIPFLAGS     => '-r',
              DIST_DEFAULT => 'tardist',
             },
);
