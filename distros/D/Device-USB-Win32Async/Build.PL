use strict;
use warnings;
use Module::Build;

die "Windows only extension.\n" unless $^O eq 'MSWin32';

if(!$ENV{LIBUSB_LIBDIR} or !$ENV{LIBUSB_INCDIR})
{
    die <<'END';
ERROR: Missing required environment variables to compile under Windows.

    LIBUSB_LIBDIR should contain the path to the libusb libraries
    LIBUSB_INCDIR should contain the path to the libusb include files

END
}

unless(header_found())
{
    die <<"END";
ERROR: Can't find usb.h header.

If the library is not installed, you will need to install it. If it is
installed somewhere other than /usr or /usr/local, you need to set the
following environment variables:

    LIBUSB_LIBDIR should contain the path to the libusb libraries
    LIBUSB_INCDIR should contain the path to the libusb include files

END
}

unless(lib_found())
{
    die <<"END";
ERROR: Can't find libusb library.

If the library is not installed, you will need to install it. If it is
installed somewhere other than /usr or /usr/local, you need to set the
following environment variables:

    LIBUSB_LIBDIR should contain the path to the libusb libraries
    LIBUSB_INCDIR should contain the path to the libusb include files

END
}

my $class = Module::Build->subclass(
	class => "Module::Build::Inline",
	code => <<'SUBCLASS' );

    sub ACTION_code {
	my $self = shift;
	$self->do_system( $^X, '-Ilib', "-MInline=NOISY,_INSTALL_", "-MDevice::USB::Win32Async", '-e1', $self->dist_version, 'blib/arch' );
	$self->SUPER::ACTION_code;
    }
SUBCLASS

my $builder = $class->new(
    module_name         => 'Device::USB::Win32Async',
    license             => 'perl',
    dist_author         => 'Rajstennaj Barrabas',
    dist_version_from   => 'lib/Device/USB/Win32Async.pm',
    requires => {
        'Test::More' => 0,
        'Device::USB' => 0.31,
    },
    add_to_cleanup      => [ 'Device-USB-Win32Async-*' ],
);

$builder->create_build_script();

sub header_found
{
    foreach my $dir (qw(/usr/include /usr/local/include), $ENV{LIBUSB_INCDIR})
    {
        return 1 if defined $dir && -e "$dir/usb.h";
    }

    return;
}

sub lib_found
{
    foreach my $dir (qw(/usr/lib /usr/local/lib), $ENV{LIBUSB_LIBDIR})
    {
        return 1 if defined $dir && (-e "$dir/libusb.lib" || -e "$dir/libusb.a");
    }

    return;
}
