use Module::Build;

my $build_pkg = eval { require Apache::TestMB }
  ? 'Apache::TestMB' : 'Module::Build';

$build_pkg->new(
    module_name        => 'MasonX::Interp::WithCallbacks',
    license            => 'perl',
    configure_requires => { 'Module::Build' => '0.2701' },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    recommends         => {
        'Test::Pod'      => '1.20',
        'Apache::TestMB' => 0
    },
    requires           => {
        'HTML::Mason'             => '1.23',
        'Test::Simple'            => '0.17',
        'Class::Container'        => '0.09',
        'Params::CallbackRequest' => '1.15',
    },
    add_to_cleanup     => ['t/mason'],
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/MasonX-Interp-WithCallbacks/',
            bugtracker => 'http://github.com/theory/masonx-interp-withcallbacks/issues/',
            repository => 'http://github.com/theory/masonx-interp-withcallbacks/',
        }
    },
)->create_build_script;
