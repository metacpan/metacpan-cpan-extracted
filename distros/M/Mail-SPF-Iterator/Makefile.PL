use ExtUtils::MakeMaker;
require 5.008;
WriteMakefile(
    NAME => 'Mail::SPF::Iterator',
    VERSION_FROM => 'lib/Mail/SPF/Iterator.pm',
    PREREQ_PM => {
	'Net::DNS' => 0.62,
	'URI' => 0,
    },
    META_MERGE => {
	resources => {
	    repository => 'https://github.com/noxxi/p5-mail-spf-iterator',
	},
    },
);

