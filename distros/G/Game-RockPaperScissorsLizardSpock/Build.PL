use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Game::RockPaperScissorsLizardSpock',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Game/RockPaperScissorsLizardSpock.pm',
    requires          => {
        'Test::More' => 0,
    },

    # delete_share => '.', # NYI https://rt.cpan.org/Ticket/Display.html?id=92863
    # install_share => 'share',
    add_to_cleanup => ['Game-RockPaperScissorsLizardSpock-*'],
);

$builder->create_build_script();

# package MY;
# use File::ShareDir::Install 0.7 qw(postamble);
# File::ShareDir::Install::delete_share('.');
