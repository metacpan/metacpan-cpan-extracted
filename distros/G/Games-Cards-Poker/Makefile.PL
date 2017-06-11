use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'           => 'Games::Cards::Poker',
# 'VERSION_FROM'   => 'lib/Games/Cards/Poker.pm',
  'VERSION'        => '1.4',
# 'ABSTRACT_FROM'  => 'lib/Games/Cards/Poker.pm',
  'ABSTRACT'       => 'Pure Perl Poker functions',
  'LICENSE'        => 'gpl_3',
  'AUTHOR'         => [ 'Pip Stuart <Pip@CPAN.Org>' ],
  'TEST_REQUIRES'  => {
    'Test'                           => 0,
    'Test::More'                     => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
  }, # Module::Name                  => 1.1,
  'PREREQ_PM'      => {
    'Algorithm::ChooseSubsets'       => 0,
  },
  'dist'           => { 'COMPRESS'   => 'gzip',
                        'SUFFIX'     => '.tgz' },
);
