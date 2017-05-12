

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Gtk2::WebKit::Mechanize',
    VERSION_FROM => 'lib/Gtk2/WebKit/Mechanize.pm', # finds \$VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Mechanize like module using WebKit browser',
    PREREQ_PM    => {
                     'Gtk2::WebKit' => ''
                    },
);
