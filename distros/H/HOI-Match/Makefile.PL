#use 5.018002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HOI::Match',
    VERSION_FROM      => 'lib/HOI/Match.pm', # finds $VERSION
    PREREQ_PM         => { Parse::Yapp::Driver => 1.05, Parse::Lex => 2.21 }, # e.g., Module::Name => 1.1
    PM                => {
        'lib/HOI/Match.pm' => '$(INST_LIBDIR)/Match.pm',
        'lib/HOI/typeparser.pm' => '$(INST_LIBDIR)/typeparser.pm'
    },
    LICENSE          => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HOI/Match.pm', # retrieve abstract from module
       AUTHOR         => 'withering <withering@cpan.org>') : ())
);
