# -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME            => 'Image::Kimdaba',
			  VERSION_FROM    => 'lib/Image/Kimdaba.pm',
			  'EXE_FILES'		=> [qw(bin/kim_bestof bin/kim_2_digikam bin/kim_category_images bin/kim_rotate.pl
							bin/kim_example.pl bin/kim_example_modifydb.pl bin/kim_jalbum.pl )]
			 );

