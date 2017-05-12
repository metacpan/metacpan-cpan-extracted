#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %eumm_params = (
    NAME              => 'HeliosX::Job::JSON',
    VERSION_FROM      => 'lib/HeliosX/Job/JSON.pm', # finds $VERSION
    AUTHOR            => 'Andrew Johnson <lajandy at cpan dot org>',
    ABSTRACT_FROM     => 'lib/HeliosX/Job/JSON.pm',
    LICENSE           => 'artistic_2',
    PREREQ_PM         => {
                          'Helios'     => 2.80,
                          'JSON::Tiny' => 0.49,    	
                         }, # e.g., Module::Name => 1.1
    EXE_FILES         => ['heliosx_job_json_submit'],
    INST_SCRIPT       => 'bin',
);

# meta
if (ExtUtils::MakeMaker->VERSION >= 6.46 ) {
	$eumm_params{META_MERGE} = {
		'meta-spec' => { version => 1.4 },
		resources => {
			repository => 'git://github.com/logicalhelion/heliosx-job-json.git',
		},
	};
}

# minimum Perl version
if (ExtUtils::MakeMaker->VERSION >= 6.48 ) {
	$eumm_params{MIN_PERL_VERSION} = 5.010;
}

WriteMakefile(%eumm_params);
