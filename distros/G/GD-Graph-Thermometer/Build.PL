use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'GD::Graph::Thermometer',
    license             => 'gpl',
    dist_author         => 'Hugh Esco <hesco@campaignfoundations.com>',
    dist_version_from   => 'lib/GD/Graph/Thermometer.pm',
    requires => {
          'Test::More' => 0,
             'version' => 0,
                  'GD' => 0,
     'GD::Text::Align' => 0,
# 'Test::Perl::Critic' => 0,
    },
    add_to_cleanup      => [ 'GD-Graph-Thermometer-*' ],
);

$builder->create_build_script();
