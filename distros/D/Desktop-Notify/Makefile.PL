use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Desktop::Notify',
    AUTHOR              => 'Stephen Cavilia <sac@atomicradi.us>',
    VERSION_FROM        => 'lib/Desktop/Notify.pm',
    ABSTRACT_FROM       => 'lib/Desktop/Notify.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
                  'Net::DBus' => 0,
                  'Class::Accessor' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Desktop-Notify-*' },
);
