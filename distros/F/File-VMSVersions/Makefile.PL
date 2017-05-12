use 5.6.0;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'           => 'File::VMSVersions',
    'VERSION_FROM'   => 'VMSVersions.pm',
    'PREREQ_PM'      => {},
    (
       $] >= 5.005 ?
       (AUTHOR => 'Thomas Kratz <ThomasKratz@web.de>') :
       ()
    ),
);
