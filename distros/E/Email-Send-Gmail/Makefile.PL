#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Email::Send::Gmail',
    'VERSION_FROM' => 'lib/Email/Send/Gmail.pm',
    'ABSTRACT'     => 'Send Messages using Gmail',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'LICENSE'      => 'perl',
    'PREREQ_PM'    => {
        'Email::Send'    => '0',
        'Email::Address' => '0',
        'Net::SMTP::SSL' => '0',
        'Authen::SASL'   => '0',
    },
);

