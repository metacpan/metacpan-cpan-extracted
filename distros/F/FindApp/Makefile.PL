use v5.10;
use strict;
use warnings;
use ExtUtils::MakeMaker;

eval "use Test::Manifest 2.00";

WriteMakefile(
    NAME             => "FindApp",
    AUTHOR           => q{Tom Christiansen <tchrist@perl.com>},
    VERSION_FROM     => "lib/FindApp.pm",
    ABSTRACT_FROM    => "lib/FindApp.pm",
    LICENSE          => "perl_5",
    PL_FILES         => {},
    EXE_FILES        => [ "bin/findapp" ],
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker"     => 0,
    },
    BUILD_REQUIRES => {
        "feature"                 =>  0,
        "lib"                     =>  0,
        "locale"                  =>  0,
        "mro"                     =>  0,
        "open"                    =>  0,
        "strict"                  =>  0,
        "utf8"                    =>  0,
        "vars"                    =>  0,
        "warnings"                =>  0,

        "Capture::Tiny"           =>  0,
        "Carp"                    =>  0,
        "Env"                     =>  0,
        "Exporter"                =>  0,
        "File::Find"              =>  0,
        "FindBin"                 =>  0,
        "Import::Base"            =>  0,
        "Package::Stash"          =>  0,
        "Pod::Coverage"           =>  0.18,
        "Pod::Coverage::Careful"  =>  1.0,
        "Scalar::Util"            =>  0,
        "Test::CheckManifest"     =>  0.9,
        "Test::Exception"         =>  0,
        "Test::Manifest"          =>  2,
        "Test::More"              =>  0,
        "Test::Pod"               =>  1.22,
        "Test::Pod::Coverage"     =>  1.08,

    },

    PREREQ_PM => {

        "charnames"         =>  0,
        "constant"          =>  0,
        "feature"           =>  0,
        "lib"               =>  0,
        "locale"            =>  0,
        "mro"               =>  0,
        "namespace::clean"  =>  0,
        "overload"          =>  0,
        "overloading"       =>  0,
        "parent"            =>  0,
        "pluskeys"          =>  2.4,
        "strict"            =>  0,
        "subs"              =>  0,
        "vars"              =>  0,
        "warnings"          =>  0,

        "Carp"              =>  0,
        "Config"            =>  0,
        "Cwd"               =>  0,
        "Data::Dump"        =>  0,
        "Env"               =>  0,
        "Exporter"          =>  0,
        "Fcntl"             =>  0,
        "File::Basename"    =>  0,
        "File::Glob"        =>  0,
        "File::Spec"        =>  0,
        "FindBin"           =>  0,
        "Getopt::Long"      =>  0,
        "List::Util"        =>  0,
        "Pod::Usage"        =>  0,
        "Scalar::Util"      =>  0,
        "Sub::Name"         =>  0,
        "Tie::Array"        =>  0,

    },
    dist  => { 
        COMPRESS => "gzip -9f", 
        SUFFIX   => "gz", 
    },
    clean => { FILES => "FindApp-*" },
);

__END__
