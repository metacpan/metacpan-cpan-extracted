use strict;
use warnings;
use ExtUtils::MakeMaker;

# eval q{
#     use File::ShareDir::Install 0.07;
#     delete_share '.'; # delete it all first
#     install_share 'share'; # install the current version second
#     *MY::postamble = \&File::ShareDir::Install::postamble;
# };
# warn "-- share/ will not be installed --\n\t$@\n-- end sharedir error --\n" if $@;

WriteMakefile(
    NAME          => 'Git::Repository::Plugin::Dirty',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Git/Repository/Plugin/Dirty.pm',
    ABSTRACT_FROM => 'lib/Git/Repository/Plugin/Dirty.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Git::Repository::Plugin' => 0,
        'Test::More'              => 0,    # unit tests
        'Test::Trap'              => 0,    # unit tests
        'Path::Tiny'              => 0,    # unit tests
        'Capture::Tiny'           => 0,    # unit tests
        'File::Temp'              => 0,    # unit tests
        Cwd                       => 0,    # unit tests
        'Git::Repository'         => 0,    # unit tests
        'Test::Exception'         => 0,    # unit tests
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Git-Repository-Plugin-Dirty-*' },
);
