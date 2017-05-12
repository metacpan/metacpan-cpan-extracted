use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Math::Fraction',
    'VERSION_FROM' => 'Fraction.pm', # finds $VERSION
    'PM'           => {'Fraction.pm' => '$(INST_LIBDIR)/Fraction.pm',
                       'FractionDemo.pm' => '$(INST_LIBDIR)/FractionDemo.pm' }
);
