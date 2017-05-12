use Module::Build;

my $build = Module::Build->new(
    module_name => 'Lingua::Deva',
    license     => 'perl',
    requires    => { perl => '5.12.1' },
);

$build->create_build_script();
