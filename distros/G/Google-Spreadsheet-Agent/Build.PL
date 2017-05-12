use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Google::Spreadsheet::Agent',
    license             => 'perl',
    dist_author         => q{Darin London <darin.london@duke.edu>},
    dist_version_from   => 'lib/Google/Spreadsheet/Agent.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Google-Spreadsheet-Agent-*' ],
    create_makefile_pl => 'small',
    requires => {
                          'Net::Google::Spreadsheets' => '>= 0.14',
                          'Moose' => '>= 0.92',
                          'YAML::Any' => '>= 0.67',
                          'Net::SMTP::TLS' => '>= 0.12',
                          'IO::CaptureOutput' => '>= 1.1101',
                 },
);

$builder->create_build_script();
