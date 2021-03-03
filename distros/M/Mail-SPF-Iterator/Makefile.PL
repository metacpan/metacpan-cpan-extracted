use ExtUtils::MakeMaker;
require 5.008;
WriteMakefile(
    NAME => 'Mail::SPF::Iterator',
    VERSION_FROM => 'lib/Mail/SPF/Iterator.pm',
    LICENSE => 'perl_5',
    PREREQ_PM => {
	'Net::DNS' => 0.62,
	'URI' => 0,
    },
    META_MERGE => {
	resources => {
            license     => 'http://dev.perl.org/licenses/',
	    repository => 'https://github.com/noxxi/p5-mail-spf-iterator',
            homepage  => 'https://github.com/noxxi/p5-mail-spf-iterator',
            bugtracker  => 'https://github.com/noxxi/p5-mail-spf-iterator/issues',
	},
    },
);

