use strict;
use warnings;

use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    'ABSTRACT_FROM' => 'lib/Device/Gsm.pm',
    'AUTHOR'        => 'Cosimo Streppone <cosimo@cpan.org>, Grzegorz Woźniak <wozniakg@gmail.com>',
    'NAME'          => 'Device::Gsm',
    'VERSION_FROM'  => 'lib/Device/Gsm.pm', # finds $VERSION
    'PREREQ_PM'     => {
        'Test::More'    => 0,
        'Device::Modem' => 1.47,
        ( ( ($^O =~ /Win/i) && (! ($^O =~ /darwin/i)) )
            ? ( 'Win32::SerialPort' => 0 )
            : ( 'Device::SerialPort'=> 0 )
        )
    },
    'LICENSE' => 'perl',
    'META_MERGE' => {
        resources => {
            repository => 'git://github.com/cosimo/perl5-device-gsm.git',
            bugtracker => 'mailto:bug-device-gsm@rt.cpan.org',
        },
    },
);

