use Module::Build;
use Alien::Base::Wrapper qw/Alien::LibJQ !export/;
use Alien::LibJQ;

my $build = Module::Build->new(
    module_name    => 'JSON::JQ',
    dist_abstract  => 'jq (https://stedolan.github.io/jq/) library binding',
    dist_author    => 'Dongxu Ma <dongxu _dot_ ma _at_ gmail.com>',
    license        => 'mit',
    configure_requires => {
        'Alien::Base::Wrapper' => '0',
        'Alien::LibJQ'         => '>= 0.04',
        'Module::Build'        => '0.42',
    },
    test_requires  => {
        'Test::Number::Delta'  => '0',
    },
    requires       => {
        'Alien::LibJQ'         => '>= 0.04',
        'JSON'                 => '0',
        'Path::Tiny'           => '0',
        'enum'                 => '0',
    },
    needs_compiler => 1,
    include_dirs   => [ '.' ], # for ppport.h
    #c_source       => 'src', # could be list too
    meta_merge     => {
        resources => {
            repository => 'https://github.com/dxma/perl5-json-jq',
            bugtracker => 'https://github.com/dxma/perl5-json-jq/issues',
        },
    },
    Alien::Base::Wrapper->mb_args,
);
$build->create_build_script;
