use v5.10;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => "Devel::WatchVars",
    AUTHOR             => q{Tom Christiansen <tchrist53147@gmail.com>},
    VERSION_FROM       => "lib/Devel/WatchVars.pm",
    ABSTRACT_FROM      => "lib/Devel/WatchVars.pm",
    LICENSE            => "perl_5",
    PL_FILES           => {},
    MIN_PERL_VERSION   => "5.010",
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 0,    # core
    },
    BUILD_REQUIRES => {
        "indirect"            => 0,
        "Capture::Tiny"       => 0,
        "Import::Base"        => 0,
        "Test::CheckManifest" => 0.9,
        "Test::Script"        => 0,
        "Test::Warn"          => 0,
        "Test2::V0"           => 0,
    },
    PREREQ_PM => {
        "overloading"              => 0, # core only as of v5.10.1 not v5.10.0.0.0.0
        "namespace::clean"         => 0,
        "Devel::GlobalDestruction" => 0,
    },
    dist  => { COMPRESS => "gzip -9f", SUFFIX => "gz" },
    clean => { FILES    => "Devel-WatchVars-*" },
);
