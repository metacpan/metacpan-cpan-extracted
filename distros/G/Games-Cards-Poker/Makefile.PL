use ExtUtils::MakeMaker;
  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # # the contents of the Makefile that is written.
  WriteMakefile(
    'NAME'         => 'Games::Cards::Poker',
    'VERSION'      => '1.2.565CHh5',
    'ABSTRACT'     => 'Pure Perl Poker functions',
    'AUTHOR'       => 'Pip Stuart <Pip@CPAN.Org>',
    'EXE_FILES'    => [ 
                    ],
    'PREREQ_PM'    => {
    'Math::BaseCnv'                  => 0,
    'Algorithm::ChooseSubsets'       => 0,
    }, # Module::Name => 1.1,
    'dist'         => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'tgz' },
  );