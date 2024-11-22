use v5.40;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Minima',
    share_dir => 'share',
    requires => {
        perl => '5.40.0',
        'Data::Dumper' => '2.1',
        'File::Share' => '0.27',
        'Hash::MultiValue', '0.16',
        'JSON' => '4.10',
        'Path::Tiny' => '0.142',
        'Plack' => '1.0050',
        'Router::Simple' => '0.17',
        'Template' => '3.100',
    },
    configure_requires => {
        'Module::Build' => '0.42',
    },
    test_requires => {
        'HTTP::Request::Common' => '6.0',
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/tessarin/Minima',
            bugtracker => 'https://github.com/tessarin/Minima/issues',
        },
    },
    license => 'mit',
);

$build->create_build_script;
