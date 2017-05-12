use 5.012003;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Math::SigDig',
    VERSION_FROM      => 'lib/Math/SigDig.pm', # finds $VERSION
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Perl extension to Math for formatting significant digits',
       AUTHOR         => 'Robert William Leach <rleach@princeton.edu>') : ()),
);
