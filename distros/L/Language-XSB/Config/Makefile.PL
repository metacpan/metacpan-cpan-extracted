use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Language::XSB::Config',
    'VERSION_FROM' => 'Config.pm.PL',
    'PREREQ_PM'	   => {},
    'AUTHOR'       => 'Salvador Fandiño <sfandino@yahoo.com>',
    'PM'           => { 'Config.pm' => '$(INST_LIBDIR)/Config.pm' },
);
