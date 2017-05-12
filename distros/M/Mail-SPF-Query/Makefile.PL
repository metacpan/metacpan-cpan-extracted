use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Mail::SPF::Query',
    VERSION_FROM        => 'lib/Mail/SPF/Query.pm',
    ABSTRACT_FROM       => 'lib/Mail/SPF/Query.pm',
    AUTHOR              => 'Meng Weng Wong <mengwong+spf@pobox.com>',
    PREREQ_PM           => {
        Sys::Hostname::Long => 0,
        Net::DNS            => 0.46,
        Net::CIDR::Lite     => 0.15,
        URI::Escape         => 0
    },
    EXE_FILES           => [
        'bin/spfd',
        'bin/spfquery'
    ]
);
