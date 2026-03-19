use strict;
use warnings;
use ExtUtils::MakeMaker;

our $VERSION = '0.2';

WriteMakefile(
    NAME         => 'Masscan::Client',
    VERSION_FROM => 'lib/Masscan/Client.pm',
    ABSTRACT     => 'Perl bindings for masscan scanning',
    AUTHOR       => 'Heitor Gouvea <hgouvea@cpan.org>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Moose'                      => 0,
        'MooseX::AttributeShortcuts' => 0,
        'MooseX::StrictConstructor'  => 0,
        'MooseX::Types::Moose'       => 0,
        'MooseX::Types::Structured'  => 0,
        'JSON'                       => 0,
        'Net::DNS'                   => 0,
    },
);
