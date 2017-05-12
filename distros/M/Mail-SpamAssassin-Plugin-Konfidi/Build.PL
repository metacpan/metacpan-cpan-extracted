use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    sign => 1,
    module_name         => 'Mail::SpamAssassin::Plugin::Konfidi',
    dist_author         => 'Dave Brondsema <dave@brondsema.net>',
    dist_version_from   => 'lib/Mail/SpamAssassin/Plugin/Konfidi.pm',
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.26,
        'Test::MockObject' => 1.08,
    },
    requires => {
        'Mail::SpamAssassin' => 3.002, # 3.2 for PerMsgStatus->got_hit()  there are alternatives for earlier if needed to support them
        'Konfidi::Client' => '1.0.3',
        'Error' => 0,
    },
    add_to_cleanup      => [ 'Mail-SpamAssassin-Plugin-Konfidi-*' ],
);

$builder->create_build_script();
