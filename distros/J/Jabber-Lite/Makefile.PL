
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME            => 'Jabber::Lite',
   VERSION_FROM    => 'lib/Jabber/Lite.pm',
   'dist' => {
	'COMPRESS' => 'gzip --best',
   },
);

