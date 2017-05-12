use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::EN::Keywords',
    'VERSION_FROM'	=> 'Keywords.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Lingua::EN::Tagger => 0
    }, # e.g., Module::Name => 1.1
);
