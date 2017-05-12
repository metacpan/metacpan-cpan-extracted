
use ExtUtils::MakeMaker;

use strict;
use warnings;

my $RngStreams_lib="";
my $RngStreams_inc="";

@ARGV = map {
    if (/^RNGSTREAMS_LIB=(.*)/) {
        $RngStreams_lib = "-L$1 ";
        ()
    }
    elsif (/^RNGSTREAMS_INCLUDE=(.*)/) {
        $RngStreams_inc = "-I$1 ";
        ()
    }
    else {
        $_
    }
} @ARGV;

WriteMakefile( NAME => 'Math::RngStream',
               VERSION_FROM => 'lib/Math/RngStream.pm',
               PREREQ_PM => {},
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS => ["${RngStreams_lib}-lrngstreams"],
               INC => "${RngStreams_inc}-I.",
               DEFINE => '', # e.g., '-DHAVE_SOMETHING'
             );
