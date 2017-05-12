use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name   => 'Lirc::Client',
    license       => 'perl',
    create_readme => 1,

    requires => {
        'perl'               => '5.006',
        'Moo'                => '1.0',
        'IO::Socket'         => '1.0',
        'Carp'               => 0,
        'File::Path::Expand' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'IO::Select' => 0,
        'IO::Handle' => 0,
    },
    configure_requires => { 'Module::Build' => '0.36', },

    meta_merge => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lirc-Client',
            repository => 'http://github.com/mvgrimes/Lirc-Client'
        }
    },
);

# LIRC doesn't work on Windows, so no need for this module to support it
die "No support for OS" if $^O eq 'MSWin32';

$build->create_build_script;
