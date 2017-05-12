use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Linux::PipeMagic',
    VERSION_FROM      => 'lib/Linux/PipeMagic.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => {
        'Test::More'    => 0,
        'File::Slurp'   => 0,
        'File::Temp'    => 0,

    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Linux/PipeMagic.pm', # retrieve abstract from module
       AUTHOR         => 'Dave Lambley <cpan@davel.org.uk>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    META_MERGE => {
        resources => {
            repository => "http://github.com/davel/Linux-PipeMagic",
        },
    },
    LICENSE           => "perl",
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw( SPLICE_F_MOVE SPLICE_F_NONBLOCK SPLICE_F_MORE SPLICE_F_GIFT ));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Linux::PipeMagic',
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
