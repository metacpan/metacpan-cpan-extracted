use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $abstract = 'Parse and convert values in Degrees/Minutes/Seconds '
             . 'formats to decimal degrees';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
    NAME              => 'Geo::Converter::dms2dd',
    VERSION_FROM      => 'lib/Geo/Converter/dms2dd.pm', # finds $VERSION
    PREREQ_PM         => {
        Carp             => 0,
        Readonly         => 0,
        'Regexp::Common' => 0,
        English          => 0,
    },
    ($] >= 5.005
        ? (
            ABSTRACT => $abstract,
            AUTHOR   => 'Shawn Laffan <shawnlaffan@gmail.com>')
        : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/geo-converter-dms2dd.git',
                web  => 'https://github.com/shawnlaffan/geo-converter-dms2dd',
                bugtracker  => 'https://github.com/shawnlaffan/geo-converter-dms2dd/issues',
            },
        },
    },
);
