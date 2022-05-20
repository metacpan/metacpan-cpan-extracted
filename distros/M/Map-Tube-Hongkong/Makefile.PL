use 5.030000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME              => 'Map::Tube::Hongkong',
    VERSION_FROM      => 'lib/Map/Tube/Hongkong.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Map/Tube/Hongkong.pm', # retrieve abstract from module
    AUTHOR            => 'FUNG Cheok Yin <fungcheokyin@gmail.com>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

package MY;
use File::ShareDir::Install 'postamble';
