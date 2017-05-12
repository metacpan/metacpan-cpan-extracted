use ExtUtils::MakeMaker ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Math::Logic',
    'VERSION_FROM' => 'Logic.pm', # finds $VERSION
    'DISTNAME'     => 'Math-Logic',
    ($] >= 5.005 ?
        (
            ABSTRACT => '2, 3 and multi-value logic; with propagating and non-propagating nulls',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'PREREQ_PM'    => {},
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" },
) ;
