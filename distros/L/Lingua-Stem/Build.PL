use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Lingua::Stem',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'Stemming of words in various languages',
        license        => 'perl',
        requires       => {
                                    'Carp' => 0,                      
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
        build_requires => { },
      )->create_build_script;
