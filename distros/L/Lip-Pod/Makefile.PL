use ExtUtils::MakeMaker;

WriteMakefile (
	NAME         => 'Lip::Pod',
	VERSION      => '0.001',
	AUTHOR       => 'Gregor N. Purdy (gregor@focusresearch.com)',
	ABSTRACT     => 'Literate Perl to POD translation',
	EXE_FILES    => [ 'lip2pod' ],
	dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);

