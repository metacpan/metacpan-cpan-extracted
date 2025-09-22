use v5.40;
use Module::Build;

my $build = Module::Build->subclass(
    class => 'Minima::Builder',
    code => <<~\EOF,
        use v5.40;
        use Path::Tiny;
        use File::ShareDir;

        sub ACTION_install ($self, @args) {
            # run normal install
            $self->SUPER::ACTION_install(@args);

            # try to clean up obsolete shared file
            try {
                require File::ShareDir;
                my $dir = File::ShareDir::dist_dir('Minima');
                my $file = path($dir, 'templates', 'etc-config.pl.stpl');
                if ($file->exists) {
                    $file->remove
                        or warn "Could not remove obsolete file $file: $!\n";
                } else {
                    say 'Updated templates.';
                }
            } catch ($e) {
                warn "Error whilre cleaning obsolete file: $e\n";
            }
        }
        EOF
)->new(
    module_name => 'Minima',
    share_dir => 'share',
    requires => {
        perl => '5.40.0',
        'Data::Dumper' => '2.1',
        'File::Share' => '0.27',
        'Hash::MultiValue', '0.16',
        'JSON' => '4.10',
        'Path::Tiny' => '0.142',
        'Plack' => '1.0050',
        'Router::Simple' => '0.17',
        'Template' => '3.100',
        'YAML::XS' => '0.904.0',
    },
    configure_requires => {
        'Module::Build' => '0.42',
    },
    test_requires => {
        'HTTP::Request::Common' => '6.0',
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/tessarin/Minima',
            bugtracker => 'https://github.com/tessarin/Minima/issues',
        },
    },
    license => 'mit',
);

$build->create_build_script;
