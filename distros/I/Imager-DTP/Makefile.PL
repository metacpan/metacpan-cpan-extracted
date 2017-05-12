use strict;
use warnings;
use ExtUtils::MakeMaker;

# Check for Imager + FreeType2 installation
eval('use Imager');
if(!$@){
	eval q(
		use Imager;
		die if(!$Imager::formats{ft2});
	);
	if($@){
		print "Your Imager must be compiled with FreeType2 option enabled.\n";
		print "Install FreeType2 and re-compile Imager with FreeType2 option enabled.\n";
		print "FreeType2 is available at <http://freetype.sourceforge.net>\n";
		exit(1);
	}
}

WriteMakefile(
    NAME                => 'Imager::DTP',
    AUTHOR              => 'Toshimasa Ishibashi <iandeth99@ybb.ne.jp>',
    VERSION_FROM        => 'lib/Imager/DTP.pod',
    ABSTRACT_FROM       => 'lib/Imager/DTP.pod',
    PL_FILES            => {},
    PREREQ_PM => {
		'Imager' => 0.39,
		'Imager::Matrix2d' => 0,
		'Test::More' => 0,
		'utf8' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Imager-DTP-*' },
);
