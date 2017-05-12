
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME            => 'Geo::Location::TimeZone',
   VERSION_FROM    => 'lib/Geo/Location/TimeZone.pm',
   'dist' => {
	'COMPRESS' => 'gzip --best',
   },
);

