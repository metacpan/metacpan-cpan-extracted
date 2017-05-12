use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Exception::Resumable',
    VERSION_FROM      => 'Resumable.pm',
    PREREQ_PM         => { },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => q|Sean O'Rourke <seano@cpan.org>|) : ()),
    ABSTRACT          => 'Resumable exceptions for Perl.',
);
