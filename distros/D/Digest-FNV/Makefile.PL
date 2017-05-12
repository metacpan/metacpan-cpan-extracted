use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Digest::FNV',
    VERSION_FROM      => 'lib/Digest/FNV.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Digest/FNV.pm', # retrieve abstract from module
       AUTHOR         => 'Jeffrey Webster <jwebster@localdomain>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    'MYEXTLIB'      => 'fnvlib/libfnv$(LIB_EXT)'
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(FNV0_32 FNV0_32_INIT FNV0_64 FNV0_64_INIT FNV1A_64_INIT
		 FNV1_32 FNV1_32A_INIT FNV1_32_INIT FNV1_64 FNV1_64_INIT
		 FNV1a_32 FNV1a_64 FNV_NONE));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Digest::FNV',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub MY::postamble {
'
$(MYEXTLIB): fnvlib/Makefile
	cd fnvlib && $(MAKE) $(PASSTHRU)
';
}
