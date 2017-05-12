use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if ($] >= 5.00503) {
  @ppd = (
    AUTHOR    => 'Alexei Rudenko <rudenko@bible.ru>',
    ABSTRACT  => 'Detects 7 Cyrillic codings and Russian or Ukrainian language'
  );
}

WriteMakefile(
    'NAME'	=> 'Lingua::DetectCyrillic',
   'VERSION_FROM' => 'DetectCyrillic.pm', 
    'PREREQ_PM' => { Unicode::Map8 => 0, Unicode::String => 0 },
    'dist' => {
      		COMPRESS => 'gzip -9f', SUFFIX => 'gz', ZIP => pkzip
	      },
   @ppd
  );

