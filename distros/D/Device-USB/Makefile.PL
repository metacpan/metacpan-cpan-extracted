use strict;
use warnings;
use Inline::MakeMaker;

if($^O eq 'MSWin32')
{
    if(!$ENV{LIBUSB_LIBDIR} or !$ENV{LIBUSB_INCDIR})
    {
        die <<'END';
ERROR: Missing required environment variables to compile under Windows.

    LIBUSB_LIBDIR should contain the path to the libusb libraries
    LIBUSB_INCDIR should contain the path to the libusb include files

END
    }
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
    NAME                => 'Device::USB',
    AUTHOR              => 'G. Wade Johnson <gwadej@cpan.org>',
    VERSION_FROM        => 'lib/Device/USB.pm',
    ABSTRACT_FROM       => 'lib/Device/USB.pm',
    LICENSE             => 'perl',
    EXE_FILES           => [ 'bin/dump_usb.pl' ],
    PL_FILES            => {},
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => 0,
        'Inline::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Inline' => 0,
        'Inline::C' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => {
        FILES => 'Device-USB-* USB.inl _Inline'
    },
    META_MERGE          => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gwadej/perl-device-usb.git',
                web  => 'https://github.com/gwadej/perl-device-usb',
            },
        },
    },
    test               => {
        TESTS => 't/*.t xt/*.t',
    },
);


sub header_found
{
    return 1 if $^O eq 'linux';

    foreach my $dir (qw(/usr/include /usr/local/include), $ENV{LIBUSB_INCDIR})
    {
        return 1 if defined $dir && -e "$dir/usb.h";
    }

    return;
}

sub lib_found
{
    return 1 if $^O eq 'linux';

    foreach my $dir (qw(/usr/local/lib64 /usr/lib64 /lib64 /usr/lib /usr/local/lib),
                     $ENV{LIBUSB_LIBDIR})
    {
        return 1 if defined $dir && ($^O =~ /win/i ? (-e "$dir/libusb.lib" || -e "$dir/libusb.a") : -e "$dir/libusb.so") ;
    }

    return;
}
