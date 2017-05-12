use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Math::Telephony::ErlangC',
    AUTHOR              => 'Flavio Poletti <flavio [at] polettix [dot] it>',
    VERSION_FROM        => 'lib/Math/Telephony/ErlangC.pm',
    ABSTRACT_FROM       => 'lib/Math/Telephony/ErlangC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Math::Telephony::ErlangB' => 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Math-Telephony-ErlangC-*' },
);
