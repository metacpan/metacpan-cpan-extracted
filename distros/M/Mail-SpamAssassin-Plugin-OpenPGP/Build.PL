use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    sign => 1,
    module_name         => 'Mail::SpamAssassin::Plugin::OpenPGP',
    dist_author         => 'Dave Brondsema <dave@brondsema.net>',
    dist_version_from   => 'lib/Mail/SpamAssassin/Plugin/OpenPGP.pm',
    build_requires => {
        # strictly for build:
        'Test::More' => 0,
        'Module::Build' => 0.26,
        # needed for testing & runtime too:
        'Mail::SpamAssassin' => 3.001, # 3.1.x+
        'Mail::GPG' => '1.0.6',
    },
    # requires => {   },
    add_to_cleanup      => [ 'Mail-SpamAssassin-Plugin-OpenPGP-*' ],
);

$builder->create_build_script();
