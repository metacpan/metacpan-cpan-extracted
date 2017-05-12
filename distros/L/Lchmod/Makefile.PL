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
    NAME          => 'Lchmod',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Lchmod.pm',
    ABSTRACT_FROM => 'lib/Lchmod.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'  => 0,    # for testing
        'File::Temp'  => 0,    # for testing
        'File::Slurp' => 0,    # for testing
        'FFI::Me'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Lchmod-*' },
);
