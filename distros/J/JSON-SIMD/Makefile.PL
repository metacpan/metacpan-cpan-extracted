use 5.008003;
use ExtUtils::MakeMaker;
use ExtUtils::CppGuess;
 
my $guess = ExtUtils::CppGuess->new;
my %cxx_options = $guess->makemaker_options;

#use Canary::Stability JSON::SIMD => 1, 5.008003;

WriteMakefile(
    dist	 => {
	             PREOP	=> 'pod2text SIMD.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	             COMPRESS	=> 'gzip -9v',
	             SUFFIX	=> '.gz',
	            },
    EXE_FILES    => [ "bin/json_simd" ],
    VERSION_FROM => "SIMD.pm",
    NAME         => "JSON::SIMD",
    PREREQ_PM    => {
       common::sense     => 0,
       Types::Serialiser => 0,
    },
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52, ExtUtils::CppGuess => 0.15 },
    OBJECT => '$(O_FILES)',
    LD => $cxx_options{CC},
    OPTIMIZE => '-O3',
    CCFLAGS => "$Config::Config{ccflags} -DSIMDJSON_EXCEPTIONS=0 -DNDEBUG",
    META_MERGE => {
        resources => {
            bugtracker => { web => "https://github.com/pjuhasz/JSON-SIMD/issues" },
            license => [ "http://dev.perl.org/licenses/" ],
            repository => {
                type => "git",
                url => "https://github.com/pjuhasz/JSON-SIMD"
            }
        }
    },
);

