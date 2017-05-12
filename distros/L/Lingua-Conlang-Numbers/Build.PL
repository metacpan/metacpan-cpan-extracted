use Module::Build;

my $build = Module::Build->new(
    module_name  => 'Lingua::Conlang::Numbers',
    license      => 'perl',
    build_requires => {
        'ok'         => '0.01',
        'Test::More' => '0.40',
    },
    requires => {
        'perl'           => '5.8.1',
        'Readonly'       => '1.03',
        'Regexp::Common' => '0.03',
    },
    recommends => {
        'Readonly::XS' => '1.02',
    },
    meta_add => {
        resources => {
            homepage   => 'http://github.com/patch/lingua-conlang-numbers',
            repository => 'git://github.com/patch/lingua-conlang-numbers.git',
        },
    },
);

$build->create_build_script;
