#
# Attention automated build system engineers:
# 
# If you're looking for a way to force the Makefile.PL to be
# created even if Keyboard Maestro Engine isn't running in an automated
# way which doesn't require you to answer "y" to the interactive prompt
# then set the PERL_KM_FORCE enviroment variable to a true value
#     -- Mark
#

use ExtUtils::MakeMaker;

BEGIN {

	# indicate for CPAN testers that we only support OS X
	unless ($^O eq "darwin") {
		die "OS unsupported\n";
	}

	# check that Keyboard Maestro is running and cowardly refuse to
	# install if it's not.
	unless (`ps x` =~ /Keyboard Maestro Engine/ || $ENV{PERL_KM_FORCE}) {
		print STDERR <<'BLURB';
This module requires Keyboard Maestro to be installed.  The Keyboard Maestro
Engine (the doohicky that sits in your menubar) doesn't seem to be running.

You can download a version of Keyboard Maestro (with a free trial) from:

     http://www.keyboardmaestro.com/

If you do not have the Keyboard Maestro Engine running when you "make test"
then the test suite will fail.

BLURB
		my $q = ExtUtils::MakeMaker::prompt("Continue with install (y/n)?","n");

		# as per http://wiki.cpantesters.org/wiki/CPANAuthorNotes
		exit 0 unless $q =~ /y/i;
	}
}

use inc::Module::Install;

name           'Mac-KeyboardMaestro';
all_from       'lib/Mac/KeyboardMaestro.pm';

requires       'Test::More'       => 0;
requires       'Mac::AppleScript' => 0.04;

license 'perl';
githubmeta;
author_tests('xt');
readme_from    'lib/Mac/KeyboardMaestro.pm';

WriteAll;
