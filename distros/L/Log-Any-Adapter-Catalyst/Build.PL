use Module::Build;

my $build = Module::Build->new(
    module_name   => 'Log::Any::Adapter::Catalyst',
    license       => 'perl',
    create_readme => 1,
    requires      => {
        'perl'              => '5.008',
        'Log::Any'          => 0,
        'Log::Any::Adapter' => 0,
        'Carp'              => 0,
    },
    build_requires => {
        'Test::More'     => 0.87,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'Catalyst::Log'  => 0,
    },
    configure_requires => { 'Module::Build' => '0.36', },
    meta_merge         => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Any-Adapter-Catalyst',
            repository => 'http://github.com/mvgrimes/log-any-catalyst',
            homepage =>
              'https://metacpan.org/module/Log::Any::Adapter::Catalyst',
        }
    },
);

$build->create_build_script;

