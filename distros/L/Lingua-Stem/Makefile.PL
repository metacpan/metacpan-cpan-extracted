use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'Lingua::Stem',
    VERSION_FROM     => 'lib/Lingua/Stem.pm',
    MIN_PERL_VERSION => '5.006',
    LICENSE          => 'perl_5',
    PREREQ_PM        => { 
              'warnings'                   => 0,
              'Lingua::Stem::Snowball::No' => '1.00',
              'Lingua::Stem::Snowball::Se' => '1.01',
              'Lingua::Stem::Snowball::Da' => '1.01',
                        'Lingua::Stem::Fr' => '0.02',
                        'Lingua::Stem::It' => 0,
                        'Lingua::Stem::Ru' => 0,
                     'Lingua::PT::Stemmer' => 0,
                     'Lingua::GL::Stemmer' => 0,
                            'Text::German' => 0,
                         },
    META_MERGE => {
       'meta-spec' => { version => 2 },
        resources => {
           bugtracker => {
                web  => 'https://github.com/JerilynFranz/perl-Lingua-Stem/issues',
            },
            homepage   => 'https://github.com/JerilynFranz/perl-Lingua-Stem',
            license    => ['http://dev.perl.org/licenses/'],
            repository => {
                type => 'git',
                url  => 'https://github.com/JerilynFranz/perl-Lingua-Stem.git',
                web  => 'https://github.com/JerilynFranz/perl-Lingua-Stem',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/Stem.pod', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

    PL_FILES         => {},
);
