#
# Attention automated build system engineers:
# 
# If you're looking for a way to force the Makefile to be created in an
# automated way which doesn't require you to answer "y" to the interactive
# prompt then set the PERL_CHOOSE_FORCE environment variable to a true value (of
# course, on your head be it to inform people that that will install commercial
# software that requires a lenience to use)
#     -- Mark
#

use ExtUtils::MakeMaker ();
use inc::Module::Install;

BEGIN {
	# indicate for CPAN testers that we only support OS X
	unless ($^O eq "darwin") {
		die "OS unsupported\n";
	}
}

print STDERR <<'BLURB';
About to Install 'choose'
-------------------------

This module will install a copy of 'choose' on your system.  You should
be aware that 'choose' is commercial software provided by Tiny Robot
Software.

     http://tinyrobotsoftware.com/choose/

'choose' is provided on a non-time limited trial basis.  If you decide
to continue to use 'choose' you should purchase a (reasonably priced)
license:

     https://sites.fastspring.com/tinyrobotsoftware/instant/choose

(This module is not affliated with Tiny Robot Software, with the
exception that they kindly allowed distribution of the binary alongside
the Perl code)

BLURB

if ($ENV{PERL_CHOOSE_FORCE}) {
	print STDERR "PERL_CHOOSE_FORCE is set, installing!";
} else {
	my $q = ExtUtils::MakeMaker::prompt(
		"Continue with install (y/n)?",
		"n"
	);

	# as per http://wiki.cpantesters.org/wiki/CPANAuthorNotes
	exit 0 unless $q =~ /y/i;
}

name           'Mac-Choose';
all_from       'lib/Mac/Choose.pm';

# need to have version 1.00 otherwise Test::File::ShareDir doesn't work
requires       'File::ShareDir'       => 1.00;

test_requires  'Test::More'           => 0;
test_requires  'Test::File::ShareDir' => 0;

license 'perl';
githubmeta;
author_tests('xt');
readme_from    'lib/Mac/Choose.pm';

# install the share stuff
install_share;

WriteAll;
