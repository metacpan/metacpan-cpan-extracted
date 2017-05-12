use Test::More tests => 6;

BEGIN {
	use_ok('Imager::DTP::Textbox::Horizontal');
	use_ok('Imager::DTP::Textbox::Vertical');
	use_ok('Imager::DTP::Line::Horizontal');
	use_ok('Imager::DTP::Line::Vertical');
	use_ok('Imager::DTP::Letter');
}

ok($Imager::formats{ft2}, 'check if Imager module is compiled with Freetype2')
or diag("Your Imager module must be compiled with Freetype2 availability.  Install Freetype2 first, and try re-compiling Imager with Makefile.PL option \"--enable freetype2\".");
