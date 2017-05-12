use Module::Build;

my $build = Module::Build->new(
    module_name   => 'Finance::Bank::Schwab',
    license       => 'perl',
    create_readme => 1,

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires => {
        'Carp'                 => 0,
        'WWW::Mechanize'       => '1.00',
        'HTML::TableExtract'   => 2,
        'LWP::Protocol::https' => '6.00',
    },

    build_requires => { # Really test_requires, but MB still doesn't handle well
        'Test::More' => 0.87,
        'File::Spec' => 0,
    },

    add_to_cleanup => [ 'Finance-Bank-Schwab-*', 'Debian_CPANTS.txt' ],
    meta_merge     => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-Schwab',
            repository => 'http://github.com/mvgrimes/Finance-Bank-Schwab'
        }
    },
);

$build->create_build_script;
