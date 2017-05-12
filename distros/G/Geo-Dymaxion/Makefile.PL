use 5.006;
use inc::Module::Install;
name		( 'Geo-Dymaxion' );
version_from	( 'Dymaxion.pm' );
build_requires	( Inline => 0.40 );
author		( 'Schuyler D. Erle <schuyler@nocat.net>' );
&Inline->write;
