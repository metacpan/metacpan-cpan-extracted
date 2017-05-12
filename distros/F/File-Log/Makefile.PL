use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'File::Log',
    'VERSION_FROM'  => 'Log.pm', # finds $VERSION
    'PREREQ_PM'     => {Carp => 1.0, Symbol => 1.0, Encode => 1.0,}, # e.g., Module::Name => 1.1
    'ABSTRACT'      => 'Log - A simple Object Orientated Logger',
    'AUTHOR'        => 'Greg George, IT Technology Solutions P/L, Australia, gng@cpan.org',
);
