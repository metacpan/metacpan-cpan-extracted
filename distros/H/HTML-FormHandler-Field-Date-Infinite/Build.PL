use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::FormHandler::Field::Date::Infinite',
    license             => 'artistic_2',
    dist_author         => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    dist_version_from   => 'lib/HTML/FormHandler/Field/Date/Infinite.pm',
    requires => {
        'HTML::FormHandler::Field::Date' => '0.03',
        'DateTime'                       => '1.06',
        'Moose'                          => '2.1005',
        'Test::Warnings'                 => '0.010',
        'Test::Most'                     => '0.34',
        'namespace::autoclean'           => '0.13',
    },
    add_to_cleanup      => [ 'HTML-FormHandler-Field-Date-Infinite-*' ],
);

$builder->create_build_script();
