#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Email::Send::Gandi',
    'VERSION_FROM' => 'lib/Email/Send/Gandi.pm',
    'ABSTRACT'     => 'Send Messages using Gandi',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'LICENSE'      => 'perl',
    'PREREQ_PM'    => {
        'Email::Send'    => '0',
        'Email::Address' => '0',
        'Net::SMTP::SSL' => '0',
        'Authen::SASL'   => '0',
    },
);

