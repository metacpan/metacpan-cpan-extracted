use ExtUtils::MakeMaker;

WriteMakefile(
      NAME      => 'GD::Barcode::Code93'
    , AUTHOR    => 'Chris DiMartino'
    , ABSTRACT  => 'Code 93 implementation of GD::Barcode family'
    , PREREQ_PM => {
          'GD::Barcode' => 0
        , 'GD'          => 0
    }
    , VERSION_FROM => 'lib/GD/Barcode/Code93.pm'
);
