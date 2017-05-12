# -*- perl -*-

use inc::Module::Install;

name('Lingua-Shakespeare');
abstract('Write poetic perl scripts');
author('Graham Barr <gbarr@cpan.org>');
version_from('lib/Lingua/Shakespeare.pm');
license('gpl');

clean_files(qw(y.tab.pl));

requires( perl => 5.004);
include_deps('Test::More');

check_nmake();      # check and download nmake.exe for Win32

&Makefile->write;
&Meta->write;

sub MY::postamble {

  return <<POSTAMBLE;

distdir : distsign

run_byacc:
	\$(PERL) mkparse Shakespeare.y lib/Lingua/Shakespeare.pm

POSTAMBLE

}

