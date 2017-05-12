#!perl
BEGIN {
    unshift @INC, 'inc';
}
use My::Builder;
use Config;
use File::Spec;


my $build = My::Builder->new(
    module_name => 'Judy',
    license => 'perl',
    configure_requires => {
        'strict'        => 0,
        'warnings'      => 0,
        'vars'          => 0,
        'Module::Build' => 0,
        'File::Spec'    => 0,
    },
    build_requires => {
        'strict'         => 0,
        'warnings'       => 0,
        'Config'         => 0,
        'vars'           => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'File::Copy'     => 0,
        'DynaLoader'     => 0,

        'Test::More'         => 0,
        'Test::Deep'         => 0,
        'ExtUtils::CBuilder' => 0,
    },
    requires => {
        'perl'       => '5.6.0',
        'strict'     => 0,
        'warnings'   => 0,
        'DynaLoader' => 0,
        'constant'   => 0,
        'Config'     => 0,

        'Sub::Exporter' => 0,
        'Alien::Judy'   => '0.26',
    },

    create_readme => 1,
    dynamic_config => 1,

    # Both of these values will be overwritten by My::Builder during
    # ACTION_build so the PERL5LIB of the moment can affect the usage
    # of -I and -L flags to find Judy.h and libJudy.so
    #
    include_dirs => [],
    extra_linker_flags => '',
);
$build->create_build_script();

