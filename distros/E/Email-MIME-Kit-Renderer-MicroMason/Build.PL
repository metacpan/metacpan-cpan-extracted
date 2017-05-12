use Module::Build;

my $build = Module::Build->new(
    module_name   => 'Email::MIME::Kit::Renderer::MicroMason',
    license       => 'perl',
    create_readme => 1,
    requires      => {
        'perl'             => '5.008',
        'Text::MicroMason' => 2.0,
        'Email::MIME::Kit' => 2.0,
        'Carp'             => 0,
    },

    configure_requires => { 'Module::Build' => '0.36', },
    build_requires     => { 'Test::More'    => 0, },

    meta_merge => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Mime-Kit-Renderer-MicroMason',
            repository =>
              'http://github.com/mvgrimes/email-mime-kit-renderer-micromason/tree/master'
        }
    },

);

$build->create_build_script;

