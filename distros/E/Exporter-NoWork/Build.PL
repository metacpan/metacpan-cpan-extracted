use Module::Build;

Module::Build->new(
    module_name     => "Exporter::NoWork",
    license         => "perl",
    requires        => {
        "Attribute::Handlers"   => "0.80",
    },
    build_requires  => {
        "Test::More"    => "0.61",
        "Test::Exports" => "1",
    },
    meta_merge      => {
        resources => {
            bugtracker => 
                "https://rt.cpan.org/Public/Dist/Display.html?Name=Exporter-NoWork",
            repository => "http://github.com/mauzo/Exporter-NoWork",
        },
    },
)->create_build_script;
