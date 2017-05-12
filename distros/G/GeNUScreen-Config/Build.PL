# vim: set ts=4 sw=4 tw=78 et si:
use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'GeNUScreen-Config-*' ],
    build_requires      => {
        'Probe::Perl'   => 0,
    },
    create_makefile_pl	=> 'passthrough',
    dist_abstract	=> 'Work with config files for GeNUScreen firewalls',
    dist_author         => 'Mathias Weidner <mamawe@cpan.org>',
    dist_version_from   => 'lib/GeNUScreen/Config.pm',
    license             => 'perl',
    module_name         => 'GeNUScreen::Config',
    requires            => {
        'Class::Std' => 0,
        'Test::More' => 0,
        'version'    => 0,
        # Perls prior to 5.6 don't support the three-argument form of open.
        'perl'	     => '5.6.0',
    },
    script_files	=> [ 'scripts/genuscreen-config.pl' ],
);

$builder->create_build_script();
