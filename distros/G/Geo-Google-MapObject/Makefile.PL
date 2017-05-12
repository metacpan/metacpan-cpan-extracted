use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME                => 'Geo::Google::MapObject',
    AUTHOR              => 'Nicholas Bamber <nicholas@periapt.co.uk>',
    VERSION_FROM        => 'lib/Geo/Google/MapObject.pm',
    ABSTRACT_FROM       => 'lib/Geo/Google/MapObject.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Test::JSON' => 0,
	'Test::Deep' => 0,
	'HTML::Template::Pluggable' => 0,
	'HTML::Entities' => 0,
	'Scalar::Util' => 0,
	'Math::Trig' => '1.2',
	'JSON'=>0
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/periapt/geo-google-mapobject',
        },
    },
    LICENSE		=> 'perl',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-Google-MapObject-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);


