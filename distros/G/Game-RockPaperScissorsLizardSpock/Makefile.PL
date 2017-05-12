use strict;
use warnings;
use ExtUtils::MakeMaker;

# eval q{
#     use File::ShareDir::Install 0.7;
#     delete_share '.';
#     install_share 'share';
#     *MY::postamble = \&File::ShareDir::Install::postamble;
# };
# warn "-- share/ will not be installed --\n\t$@\n-- end sharedir error --\n" if $@;

WriteMakefile(
    NAME          => 'Game::RockPaperScissorsLizardSpock',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Game/RockPaperScissorsLizardSpock.pm',
    ABSTRACT_FROM => 'lib/Game/RockPaperScissorsLizardSpock.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Game-RockPaperScissorsLizardSpock-*' },
);
