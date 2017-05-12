# $Id: Makefile.PL,v 1.1.1.1 2003/02/01 10:28:26 florian Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
        package MY;
        shift->SUPER::postamble . <<'MAKE';
distdir : README

README : EXPN.pm
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

MAKE
}

WriteMakefile(
    'NAME'	=> 'Mail::EXPN',
    'VERSION_FROM' => 'EXPN.pm', # finds $VERSION
    'dist' => {'COMPRESS' => 'gzip --best --force'},
    'PREREQ_PM' => {'Net::DNS' => 0},
);
