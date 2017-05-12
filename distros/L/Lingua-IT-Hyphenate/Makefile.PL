use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'  => 'Lingua::IT::Hyphenate',
    'VERSION_FROM' => 'Hyphenate.pm',
    'dist' => { 'COMPRESS' => 'gzip' },
    ($] < 5.005 ? () : (
		'AUTHOR'        	=> 'Aldo Calpini <dada@perl.it>',
		'ABSTRACT'      	=> 'Italian word hyphenation',
    )),   
);
