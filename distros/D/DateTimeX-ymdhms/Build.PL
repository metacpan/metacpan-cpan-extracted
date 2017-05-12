use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DateTimeX::ymdhms',
    license             => 'perl',
    dist_author         => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    dist_version_from   => 'lib/DateTimeX/ymdhms.pm',
    requires => {
                 'DateTime'            => '1.01',
                 'Test::Most'          => '0.25',
                 'Test::Perl::Critic'  => '1.02',
                 'Test::Pod'           => '1.45',
                 'Test::Pod::Coverage' => '1.08',
    },
    add_to_cleanup      => [ 'DateTimeX-ymdhms-*' ],
);

$builder->create_build_script();
