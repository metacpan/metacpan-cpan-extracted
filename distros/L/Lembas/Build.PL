use 5.006;
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'Module::Build::WithDebuild',
    code => q{
        sub ACTION_debuild {
            system("debuild -i -us -uc -b");
        }
    },
    );

my $builder = $class->new(
    module_name         => 'Lembas',
    license             => 'perl',
    dist_author         => q{Fabrice Gabolde <fabrice.gabolde@gmail.com>},
    dist_version_from   => 'lib/Lembas.pm',
    dist_abstract       => 'Testing framework for command line applications inspired by Cram',
    configure_requires => { 'Module::Build' => '0.36_14' },
    build_requires => {
        'File::Spec' => 0,
        'IO::Scalar' => 0,
        'Test::Builder::Tester' => 0,
        'Test::Exception' => 0,
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.010,
        'IPC::Run' => 0,
        'List::Util' => 0,
        'Moo::Lax' => 0,
        'Params::Validate' => 0,
        'Test::Builder::Module' => 0,
        'Text::ParseWords' => 0,
    },
    recursive_test_files => 1,
    add_to_cleanup      => [ 'Lembas-*' ],
    meta_merge          => { resources =>
                             { repository => 'https://bitbucket.org/fgabolde/Lembas' } },
);

$builder->create_build_script();
