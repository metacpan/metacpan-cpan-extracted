use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => { 'Test::MobileAgent' => '0' },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        'perl'              => '5.00800',
        'parent'            => '0',
        'HTTP::MobileAgent' => '0'
    },
    no_index    => { 'directory' => [ 't', 'inc' ] },
    name        => 'HTML-Pictogram-MobileJp',
    module_name => 'HTML::Pictogram::MobileJp',

    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
