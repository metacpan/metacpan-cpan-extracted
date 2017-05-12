use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Linux::Personality',
    VERSION_FROM      => 'lib/Linux/Personality.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Linux/Personality.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Schwigon <ss5@nonet>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(),
#              {name=>"ADDR_COMPAT_LAYOUT", macro=>"1"}, # not in 2.6.28
              {name=>"ADDR_LIMIT_32BIT", macro=>"1"},
              {name=>"ADDR_LIMIT_3GB", macro=>"1"},
              {name=>"ADDR_NO_RANDOMIZE", macro=>"1"},
              {name=>"MMAP_PAGE_ZERO", macro=>"1"},
              {name=>"PER_BSD", macro=>"1"},
              {name=>"PER_HPUX", macro=>"1"},
              {name=>"PER_IRIX32", macro=>"1"},
              {name=>"PER_IRIX64", macro=>"1"},
              {name=>"PER_IRIXN32", macro=>"1"},
              {name=>"PER_ISCR4", macro=>"1"},
              {name=>"PER_LINUX", macro=>"1"},
              {name=>"PER_LINUX32", macro=>"1"},
              {name=>"PER_LINUX32_3GB", macro=>"1"},
              {name=>"PER_LINUX_32BIT", macro=>"1"},
              {name=>"PER_MASK", macro=>"1"},
              {name=>"PER_OSF4", macro=>"1"},
              {name=>"PER_OSR5", macro=>"1"},
              {name=>"PER_RISCOS", macro=>"1"},
              {name=>"PER_SCOSVR3", macro=>"1"},
              {name=>"PER_SOLARIS", macro=>"1"},
              {name=>"PER_SUNOS", macro=>"1"},
              {name=>"PER_SVR3", macro=>"1"},
              {name=>"PER_SVR4", macro=>"1"},
              {name=>"PER_UW7", macro=>"1"},
              {name=>"PER_WYSEV386", macro=>"1"},
              {name=>"PER_XENIX", macro=>"1"},
#              {name=>"READ_IMPLIES_EXEC", macro=>"1"}, # not in 2.6.28
              {name=>"SHORT_INODE", macro=>"1"},
              {name=>"STICKY_TIMEOUTS", macro=>"1"},
              {name=>"WHOLE_SECONDS", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Linux::Personality',
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
