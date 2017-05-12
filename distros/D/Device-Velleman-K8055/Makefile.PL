use strict;
use warnings;
use ExtUtils::MakeMaker;

die "Device::Velleman::K8055 can currently only be installed on Microsoft Windows Platforms\n Makefile not written\n\n" unless $^O eq 'MSWin32';

WriteMakefile(
    NAME                => 'Device::Velleman::K8055',
    AUTHOR              => 'Jouke <jouke@pvoice.org>',
    VERSION_FROM        => 'lib\Device\Velleman\K8055.pm',
    ABSTRACT_FROM       => 'lib\Device\Velleman\K8055.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Win32::API' => 0.40,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-Velleman-K8055-*' },
);

print <<NOTIFICATION;
# 
# This module is a simple wrapper around the K8055D.DLL that 
# Velleman supplies with the K8055 USB kit. Therefore you need
# to copy this DLL in a directory in your path (e.g. C:\\WINDOWS)
# The DLL can be found inside this package.
#
# Now, to continue, type:
#
#       nmake
#       nmake test
#       nmake install
#
# Only run nmake test if you have connected the K8055 to your machine
# and you have set the device number to 0.
# See the enclosed README for more information.
# 
NOTIFICATION
