use strict;
use warnings;
use Inline::MakeMaker;

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

WriteMakefile(
    NAME                => 'Device::USB::Win32Async',
    AUTHOR              => 'Rajstennaj Barrabas',
    VERSION_FROM        => 'lib/Device/USB/Win32Async.pm',
    ABSTRACT_FROM       => 'lib/Device/USB/Win32Async.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Device::USB' => 0.31,
	'Inline' => 0,
	'Inline::C' => 0,
	'Inline::MakeMaker' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-USB-Win32Async-* Win32Async.inl _Inline' },
);

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
