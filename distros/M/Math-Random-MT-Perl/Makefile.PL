use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'Math::Random::MT::Perl',
    VERSION_FROM      => 'lib/Math/Random/MT/Perl.pm',
    PREREQ_PM         => {
        'Test::More'          => 0,
        'Test::Number::Delta' => 0,
        get_opt_test_mods(),
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Math/Random/MT/Perl.pm',
       AUTHOR         => 'Dr James Freeman') :
      ()
    ),
    LICENSE           => 'artistic_2',
    realclean         => { FILES => 'Math-Random-MT-Perl* *.tmp *.bak' },
);


sub get_opt_test_mods {
   # Find which optional modules used in unit tests are available
   my @avail_mods;
   my %opt_modules = (
      'Math::Random::MT'    =>  0,
      'Test::Kwalitee'      =>  0,
      'Test::Pod'           => '1.00',
      'Test::Pod::Coverage' => '1.00',
      'Test::Spelling'      =>  0,
   );

   while (my ($module, $version) = each %opt_modules) {
      eval "require $module;";
      if (! $@) {
         push @avail_mods, $module, $version;
      }
   }
   return @avail_mods;
}
