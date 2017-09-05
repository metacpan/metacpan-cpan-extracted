use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lab::VXI11',
    VERSION_FROM      => 'lib/Lab/VXI11.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Lab/VXI11.pm', # retrieve abstract from module
    AUTHOR            => "Simon Reinhardt <simon.reinhardt\@stud.uni-regensburg.de>",
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    CCFLAGS           => '-Wall',
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'http://www.labmeasurement.de',
            repository => {
                type => 'git',
                url => 'git://github.com/lab-measurement/Lab-VXI11.git',
                web => 'https://github.com/lab-measurement/Lab-VXI11',
            },
            x_MailingList => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-measurement-users',
            x_IRC => 'irc://chat.freenode.net/#labmeasurement',
        }
    }
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(DEVICE_ASYNC DEVICE_ASYNC_VERSION DEVICE_CORE
		 DEVICE_CORE_VERSION DEVICE_INTR DEVICE_INTR_VERSION),
              {name=>"DEVICE_TCP", macro=>"1"},
              {name=>"DEVICE_UDP", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Lab::VXI11',
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
