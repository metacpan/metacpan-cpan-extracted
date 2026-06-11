use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
    NAME         => 'IFNGENO::GenoPheno::Utils',
    VERSION_FROM => 'lib/IFNGENO/GenoPheno/Utils.pm',
    ABSTRACT     => 'Utility functions for GenoPheno SNP processing',
    AUTHOR       => 'Samira Ghareh Gozlou <samira.grgzlo@gmail.com>',
    LICENSE      => 'perl',

    
	PREREQ_PM => {
			'JSON' => 0,
	},
);
