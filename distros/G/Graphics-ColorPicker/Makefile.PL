use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
   'NAME'         => 'Graphics::ColorPicker',
   'VERSION_FROM' => 'ColorPicker.pm',	# finds $VERSION
   'PM'           => {'ColorPicker.pm'	=> '$(INST_LIBDIR)/'.'ColorPicker.pm'},
   'dist'         => {COMPRESS	=> 'gzip', SUFFIX => 'gz'}
);
