use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Lingua::FR::Nums2Words',
    VERSION_FROM      => 'lib/Lingua/FR/Nums2Words.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Lingua/FR/Nums2Words.pm',
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>') : ()),
);
