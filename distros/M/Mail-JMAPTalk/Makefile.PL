use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mail::JMAPTalk',
    VERSION_FROM      => 'lib/Mail/JMAPTalk.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Convert::Base64' => 0,
        'JSON'            => 0,
        'File::LibMagic' => 0,
        'HTTP::Tiny'     => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Mail/JMAPTalk.pm', # retrieve abstract from module
    AUTHOR            => 'Bron Gondwana <brong@>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
