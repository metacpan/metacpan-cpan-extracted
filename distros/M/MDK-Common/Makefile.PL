use ExtUtils::MakeMaker;

if (-e 'lib/MDK/Common.pm.pl') {
    system("perl lib/MDK/Common.pm.pl > lib/MDK/Common.pm");
}

WriteMakefile(
    NAME          => 'MDK::Common',
    VERSION_FROM  => 'lib/MDK/Common.pm',
    ABSTRACT_FROM => 'lib/MDK/Common.pm',
    AUTHOR        => 'Pixel <pixel@mandriva.com>',
    dist	  => { COMPRESS => "xz -f" },
);
