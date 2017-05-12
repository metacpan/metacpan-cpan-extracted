use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
    NAME          => 'Math::Fraction::Egyptian',
    AUTHOR        => 'John Trammell <johntrammell <at> gmail <dot> com>',
    VERSION_FROM  => 'lib/Math/Fraction/Egyptian.pm',
    ABSTRACT_FROM => 'lib/Math/Fraction/Egyptian.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'Test::Warn'      => 0,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    clean => {
        FILES => [ 'cover_db', 'Math-Fraction-Egyptian-*', '*.bak' ],
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 6.3002) {
    $params{LICENSE} = 'perl';
}

# add coverage to makefile
sub MY::postamble {
    return "\ntestcover:\n\tcover -test\n\n";
}

WriteMakefile(%params);

