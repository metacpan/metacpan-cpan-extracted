use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Inline::CPR',
	      VERSION_FROM => 'CPR.pm',
	      PREREQ_PM => {Inline => '0.41'},
	      EXE_FILES => ['./script/cpr.pl'],
	      clean => {FILES => 'examples/ _cpr/ .cpr/'},
	     );


sub MY::processPL {
    <<'END';
# --- MakeMaker processPL section:

all :: examples/synopsis.cpr
	@$(NOOP)

examples/synopsis.cpr :: bin/synopsis.PL
	$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) bin/synopsis.PL $(INSTALLBIN)

END
}
