use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @ppd = ();
if ($] >= 5.00503) {
	@ppd = (
		'AUTHOR'   => 'Henrique Dias <henrique.ribeiro.dias@gmail.com>',
		'ABSTRACT' => 'Extension for explode MIME messages',
	);
}

WriteMakefile(
	'NAME'         => 'MIME::Explode',
	'DISTNAME'     => 'MIME-Explode',
	'VERSION_FROM' => 'Explode.pm', # finds $VERSION
	'LICENSE'      => 'perl',
	'LIBS'         => [''],   # e.g., '-lm' 
	'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING' 
	'INC'          => '',     # e.g., '-I/usr/include/other' 
	'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
	@ppd,
);
