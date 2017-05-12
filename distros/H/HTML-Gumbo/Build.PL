use Module::Build;
use Alien::LibGumbo;

my $alien = Alien::LibGumbo->new;
my $builder = Module::Build->new(
    module_name => 'HTML::Gumbo',
    license => 'perl',
    create_license => 1,

    configure_requires => {
        'Module::Build' => 0.42,
        'Alien::LibGumbo' => 0,
    },
    build_requires => {
        'ExtUtils::CBuilder' => 0,
    },
    requires => {
        'Alien::LibGumbo' => '0.03',
        'XSLoader' => 0,
    },

    meta_merge => {
        resources => {
            repository => 'https://github.com/ruz/HTML-Gumbo'
        }
    },

    add_to_cleanup => [ 'HTML-Gumbo-*' ],

    extra_compiler_flags => $alien->cflags(),
    extra_linker_flags   => $alien->libs(),
);
$builder->create_build_script;
