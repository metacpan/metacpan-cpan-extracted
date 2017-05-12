use Module::Build;
my $build = Module::Build->new(
    module_name        => 'Media::DateTime',
    license            => 'perl',
    create_readme      => 1,
    requires           => {
        'perl'              => '5.008',
        'Carp'              => 0,
        'Hash::Util'        => 0.05,
        'Module::Pluggable' => 0,
        'Image::ExifTool'   => 0,
        'DateTime'          => 0,
        'Try::Tiny'         => 0,
    },
    build_requires => {
        'Test::More'         => 0,
        'DateTime::TimeZone' => 0,
        'File::Which'        => 0,
    },
    recommends => {},

    meta_merge => {
        resources => {
            bugtracker => 'http://github.com/mvgrimes/media-datetime/issues',
            repository => 'http://github.com/mvgrimes/media-datetime',
        }
    },
);

# $build->add_build_element('gif');
$build->create_build_script;

