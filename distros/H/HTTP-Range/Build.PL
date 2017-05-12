use Module::Build;
my $build = new Module::Build
    (
        module_name         => 'HTTP::Range',
        dist_version_from   => 'lib/HTTP/Range.pm',
        author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
        license             => 'perl',
        requires            => {
            IO::String          => '1.05',
            HTTP::Request       => '1.40',
            HTTP::Response      => '1.49',
            HTTP::Status        => '1.28',
            HTTP::Message       => '1.44',
            Set::Infinite       => '0.59',
            Params::Validate    => '0.74',
        },
        recommends          => {
            Storable            => '2.00',
            Test::Pod           => '0.95',
            File::Find::Rule    => '0.24',
        },
    );
$build->create_build_script;
