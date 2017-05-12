use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Digest::Adler32::XS',
    AUTHOR          => 'Stuart Watt <swatt@infobal.com>',
    VERSION_FROM    => 'lib/Digest/Adler32/XS.pm',
    ABSTRACT_FROM   => 'lib/Digest/Adler32/XS.pm',
    LICENSE         => 'lgpl',
    BUILD_REQUIRES  => {'Test::More' => 0},
    META_MERGE      => {optional_features =>
                            {benchmark_tests =>
                                {description => 'Include the benchmark tests against Digest::Adler32.',
                                 requires =>
                                    {'Digest::Adler32' =>     0,
                                     'Time::HiRes'     =>     0}}}},        
);

