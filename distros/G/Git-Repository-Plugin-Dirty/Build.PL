use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Git::Repository::Plugin::Dirty',
    license           => 'artistic2',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Git/Repository/Plugin/Dirty.pm',
    requires          => {
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

    # delete_share => '.', # NYI https://rt.cpan.org/Ticket/Display.html?id=92863
    # install_share => 'share',
    add_to_cleanup => ['Git-Repository-Plugin-Dirty-*'],
);

$builder->create_build_script();

# package MY;
# use File::ShareDir::Install 0.07 qw(postamble);
# File::ShareDir::Install::delete_share('.');
