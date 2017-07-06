use 5.008000;
use ExtUtils::MakeMaker;
use Alien::HIDAPI;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::HID::XS',
    VERSION_FROM      => 'lib/Device/HID/XS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Device/HID/XS.pm', # retrieve abstract from module
    AUTHOR            => 'Ahmad Fatoum <ahmad@a3f.at>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => Alien::HIDAPI->libs, # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => Alien::HIDAPI->cflags,
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
