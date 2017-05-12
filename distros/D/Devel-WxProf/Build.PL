use Module::Build;
use version;
$build = Module::Build->new(
    dist_author        => 'Martin Kutter <martin.kutter@fen-net.de>',
    create_makefile_pl => 'small',
    dist_abstract      => 'heavy-weight subroutine profiler and graphical profile analyzer',
    dist_name          => 'Devel-WxProf',
    dist_version       => q(0.0.1),
    module_name        => 'Devel::WxProf',
    license            => 'artistic',
    requires           => {
        'perl'              => q(5.8.0),
        'Wx'                => 0,
        'Time::HiRes'       => 0,
        'Imager'            => 0,
        'Class::Std::Fast'  => q(0.0.5),
        'File::Basename'    => 0,
        'File::Path'        => 0,
        'Getopt::Long'      => 0,
        'List::Util'        => 0,
        'YAML'              => 0
    },
    build_requires => {
        'Class::Std::Fast'        => q(0.0.5),
        'Wx'                => 0,
        'Time::HiRes'       => 0,
        'Imager'            => 0,
        'Class::Std::Fast'  => q(0.0.5),
        'File::Basename'    => 0,
        'File::Path'        => 0,
        'Getopt::Long'      => 0,
        'List::Util'        => 0,
        'YAML'              => 0,
        'Test::More'        => 0,
    },
    recursive_test_files => 1,
);
$build->create_build_script;