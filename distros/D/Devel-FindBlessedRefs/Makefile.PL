use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Devel::FindBlessedRefs',
    VERSION_FROM => 'FindBlessedRefs.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['blessed','refs'],
                resources=> {
                    repository => 'http://github.com/jettero/devel--findblessedrefs/',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),
);
