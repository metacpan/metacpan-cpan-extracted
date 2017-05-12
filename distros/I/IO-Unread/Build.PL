use Module::Build;

use 5.008001;

Module::Build->new(
    module_name     => "IO::Unread",
    license         => "perl",
    include_dirs    => ".",
    requires        => {
        perl => "5.008001",
    },
    meta_merge      => {
        resources => {
            repository => "http://github.com/mauzo/IO-Unread",
        },
    },
)->create_build_script;
