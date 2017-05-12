use ExtUtils::MakeMaker;
WriteMakefile
(
          'PL_FILES' => {},
          'INSTALLDIRS' => 'site',
          'NAME' => 'Image::Fixup',
          'EXE_FILES' => [],
          'VERSION_FROM' => 'lib/Image/Fixup.pm',
          'PREREQ_PM' => {
                           'Carp' => 0,
                           'Test::More' => 0,
                           'Class::Light' => '0.01002'
                         }
        )
;
