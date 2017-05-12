use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $IS_WINDOWS = ($^O eq "MSWin32" or $^O eq "cygwin") ? 1 : 0;
my %SERIAL;
if ($IS_WINDOWS) {
    %SERIAL=('Win32::SerialPort' => 0);
} else {
    %SERIAL=('Device::SerialPort' => 0);
}

my $builder = Module::Build->new(
    module_name         => 'Device::MiniLED',
    license             => 'Artistic_2_0',
    dist_author         => q{Kerry Schwab <sales@brightledsigns.com>},
    dist_version_from   => 'lib/Device/MiniLED.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        %SERIAL,
        'POSIX'      => 0,
        'Carp'       => 0
      
    },
    add_to_cleanup     => [ 'Device-MiniLED-*' ],
);
$builder->create_build_script();
