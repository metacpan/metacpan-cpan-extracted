use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::Chipmunk',
    VERSION_FROM      => 'lib/Games/Chipmunk.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Alien::Chipmunk' => '0.001002',
    },
    TEST_REQUIRES => {
        'Test::Pod' => '1.51',
    },
    ABSTRACT_FROM     => 'lib/Games/Chipmunk.pm',
    AUTHOR            => 'tmurray <tmurray@wumpus-cave.net>',
    LICENSE           => 'bsd',
    LIBS              => ['-lchipmunk'], # e.g., '-lm'
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
  my @names = (qw(CP_ALLOW_PRIVATE_ACCESS CP_BUFFER_BYTES CP_VERSION_MAJOR
		 CP_VERSION_MINOR CP_VERSION_RELEASE cpcalloc cpfree cprealloc));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Games::Chipmunk',
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
