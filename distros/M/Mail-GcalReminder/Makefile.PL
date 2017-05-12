use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Mail::GcalReminder',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Mail/GcalReminder.pm',
    ABSTRACT_FROM => 'lib/Mail/GcalReminder.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'  => 0,
        'Test::Deep'  => 0,
        'Net::Detect' => 0,
        'Test::Warn'  => 0,

        'Moo'                 => 0,
        'Role::Multiton::New' => 0,

        'Email::Send::SMTP::Gmail' => 0,
        'iCal::Parser'             => 0,
        'File::Temp'               => 0,
        'HTML::Tiny'               => 0,

        'DateTime'                  => 0,
        'DateTime::TimeZone'        => 0,
        'Carp'                      => 0,
        'DateTime::Format::ISO8601' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Mail-GcalReminder-*' },
);
