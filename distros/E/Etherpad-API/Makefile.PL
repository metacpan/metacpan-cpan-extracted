

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Etherpad::API',
    VERSION_FROM => 'lib/Etherpad/API.pm', # finds \$VERSION
    AUTHOR       => 'Luc DIDRY (ldidry@cpan.org)',
    ABSTRACT     => 'Access Etherpad Lite API easily',
    PREREQ_PM    => {
                     'Etherpad' => '0',
                     'Test::Simple' => 0.44,
                    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/ldidry/etherpad-api.git',
                web  => 'https://github.com/ldidry/etherpad-api',
            },
        },
    },
);
