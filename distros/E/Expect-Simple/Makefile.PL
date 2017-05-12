use ExtUtils::MakeMaker;
my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Expect::Simple',
    VERSION_FROM      => 'lib/Expect/Simple.pm', # finds $VERSION
    PREREQ_PM         => { Expect => 0,
			   Test::More => 0,
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Expect/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Diab Jerius <djerius@cpan.org>') : ()),
    ( $EUMM_VERSION >= 6.31 ? (
        LICENSE         => 'gpl',
    ) : ()),
);
