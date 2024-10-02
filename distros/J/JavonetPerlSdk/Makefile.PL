use ExtUtils::MakeMaker;
use strict;
use warnings;

my %WriteMakefileArgs = (
    NAME                => 'JavonetPerlSdk',
    VERSION_FROM        => 'VERSION',
    AUTHOR              => 'SdNCenter Sp. z o.o',
    ABSTRACT            => 'Javonet allows you to reference and use modules or packages written in (Java/Kotlin/Groovy/Clojure, C#/VB.NET, Ruby, Perl, Python, JavaScript/TypeScript) like they were created in your technology. It works on Linux/Windows and MacOS for applications created in JVM, CLR/Netcore, Perl, Python, Ruby, NodeJS, C++ or GoLang and gives you unparalleled freedom and flexibility with native performance in building your mixed-technologies products. Let it be accessing best AI or cryptography libraries, devices SDKs, legacy client modules, internal custom packages or anything from public repositories available on NPM, Nuget, PyPI, Maven/Gradle, RubyGems or GitHub. Get free from programming languages barriers today! For more information check out our guides at https://www.javonet.com/guides/v2/',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
         'Attribute::Abstract' => '0',
         'autobox::universal' => '0',
         'aliased' => '0',
         'Data::Cmp' => '0',
         'Data::UUID' => '0',
         'DateTime' => '0',
         'FFI::Platypus' => '0',
         'IO::Socket::SSL' => '0',
         'JSON' => '0',
         'LWP::UserAgent' => '0',
         'Moose' => '0',
         'Nice::Try' => '0',
         'Path::Tiny' => '0',
         'Scalar::Util::Numeric' => '0',
         'Sys::Hostname' => '0',
         'threads' => '0',
         'Config' => '0',
    },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
    })),
);

WriteMakefile(%WriteMakefileArgs);
