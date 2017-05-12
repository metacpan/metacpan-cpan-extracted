use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'HTML::DublinCore',
    VERSION_FROM  => 'lib/HTML/DublinCore.pm', 
    ABSTRACT_FROM => 'lib/HTML/DublinCore.pm', 
    AUTHOR        => 'Ed Summers <ehs@pobox.com>',
    PREREQ_PM     => 
        {
             DublinCore::Record => 0,
             HTML::Parser       => 3.0,
        },
);
