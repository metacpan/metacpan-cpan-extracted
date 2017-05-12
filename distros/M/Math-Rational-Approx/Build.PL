use Module::Build;

Module::Build->new(

    module_name => 'Math::Rational::Approx',

    license              => 'gpl3',
    create_license       => 1,
    create_readme        => 1,
    recursive_test_files => 1,
    sign                 => 1,

    requires => {

        'Moo'                             => 0,
        'MooX::Types::MooseLike::Numeric' => 0,
        'POSIX'                           => 0,
        'Params::Validate'                => 0,
    },

    test_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'Math::Trig'      => 0,
    },

    meta_merge => {

        resources => {
            repository => 'https://bitbucket.org/djerius/math-rational-approx',
        },
    },

)->create_build_script;

