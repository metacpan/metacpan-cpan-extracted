use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.



check_fonts();

WriteMakefile(
    'NAME'	   => 'Imager::Plot',
    'VERSION_FROM' => 'Plot.pm', # finds $VERSION
    'PREREQ_PM'    => { Imager => 0.41 }
);


sub check_fonts {
  require Imager;
  die "Unable to load any fonts!\n".
    "please make sure that Imager was compiled with support\n".
      "for one of the following libraries: freetype1, freetype2, libt1, win32\n"
	unless
	  Imager::Font->new(file=>'ImUgly.ttf') ||
	      Imager::Font->new(file=>"./dcr10.pfb");
}

