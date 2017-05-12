use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::ListScraper',
    AUTHOR              => 'Vaclav Barta <vbar@comp.cz>',
    VERSION_FROM        => 'lib/HTML/ListScraper.pm',
    ABSTRACT_FROM       => 'lib/HTML/ListScraper.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'HTML::Parser' => 0,
	'Class::Generate' => 0,
	'Algorithm::NeedlemanWunsch' => '0.04',
	'LWP' => 0,
        'IPC::Run3'=> 0,
        'Probe::Perl' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-ListScraper-*' },
);

