use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Exporter::Simple',
    'VERSION_FROM'	=> 'lib/Exporter/Simple.pm',
    'PREREQ_PM'		=> {
    	Attribute::Handlers => '0.77',
    },
    dist                => {
        COMPRESS => 'gzip --force --best'
    },
);
