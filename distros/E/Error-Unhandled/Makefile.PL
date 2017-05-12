use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'  => 'Error::Unhandled',
  'VERSION_FROM' => 'Error/Unhandled.pm', # finds $VERSION
  'PM' => {
    'Error/Unhandled.pm' => '$(INST_LIBDIR)/Unhandled.pm',
  },
);
