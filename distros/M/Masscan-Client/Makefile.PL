use strict;
use warnings;
use ExtUtils::MakeMaker;

our $VERSION = '0.21';

WriteMakefile(
    NAME         => 'Masscan::Client',
    VERSION_FROM => 'lib/Masscan/Client.pm',
    ABSTRACT     => 'Perl bindings for masscan scanning',
    AUTHOR       => 'Heitor Gouvea <hgouvea@cpan.org>',
    LICENSE      => 'perl',
    MIN_PERL_VERSION => '5.020000',
    PREREQ_PM    => {
        'Data::Validate::Domain'      => '0.15',
        'Data::Validate::IP'          => '0.31',
        'JSON'                       => '4.11',
        'Log::Log4perl'              => '1.57',
        'Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors' => '0.117',
        'Moose'                      => '2.4000',
        'MooseX::AttributeShortcuts' => '0.037',
        'MooseX::StrictConstructor'  => '0.21',
        'MooseX::Types::Moose'       => '0.51',
        'MooseX::Types::Structured'  => '0.36',
        'namespace::autoclean'       => '0.31',
        'Net::DNS'                   => '1.54',
        'Try::Catch'                 => '1.1.0',
    },
);
