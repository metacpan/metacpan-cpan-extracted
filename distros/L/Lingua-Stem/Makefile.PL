use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'           => 'Lingua::Stem',
    'VERSION_FROM'   => 'lib/Lingua/Stem.pm',
    'PREREQ_PM'      => { 
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
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/Stem.pod', # retrieve abstract from module
       AUTHOR         => 'Benjamin Franz <snowhare@nihongo.org>') : ()),

       ($] >= 5.800 ?     ## Add these new keywords supported since 5.8
             (NO_META      => 1) : ()),

    PL_FILES         => {},
    'linkext'        => { LINKTYPE => '' },    # no link needed
    'dist'           => { 'COMPRESS' => 'gzip -9f', 
                            'SUFFIX' => 'gz',
                               'ZIP' => '/usr/bin/zip',
                          'ZIPFLAGS' => '-rl'
                        }
);
