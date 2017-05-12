use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Gtk3::SourceView',
    VERSION_FROM      => 'lib/Gtk3/SourceView.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Glib::Object::Introspection' => 0, 'Gtk3' => 0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Gtk3/SourceView.pm', # retrieve abstract from module
    AUTHOR            => 'Maximilian Lika <Maximilian-Lika@gmx.de>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
