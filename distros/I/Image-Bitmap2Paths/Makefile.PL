use 5.022002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Bitmap2Paths',
    VERSION_FROM      => 'lib/Image/Bitmap2Paths.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Data::Flow' => 0.09}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Image/Bitmap2Paths.pm', # retrieve abstract from module
    AUTHOR            => 'Ilya Zakharevich <ilyaz@cpan.com>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
