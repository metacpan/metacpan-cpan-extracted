die "OS Unsupported" if ($^O !~ m#(?i)Linux#);

use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Linux::Unshare',
    VERSION_FROM      => 'lib/Linux/Unshare.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Linux/Unshare.pm',
       AUTHOR         => [ 'Boris Sukholitko <boris@>', 'Marian Marinov <HackMan>' ]) : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
if (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(CLONE_THREAD CLONE_FS CLONE_NEWNS CLONE_SIGHAND CLONE_VM
	  CLONE_FILES CLONE_SYSVSEM CLONE_NEWUTS CLONE_NEWIPC CLONE_NEWNET CLONE_NEWUSER ));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Linux::Unshare',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc'
                                  );
} else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
