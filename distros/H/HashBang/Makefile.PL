use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'HashBang',
    VERSION_FROM => 'hashbang.pm',
    EXE_FILES => [ 'bin/hashbang' ],
    clean => { FILES => 'bin' },
);

sub MY::postamble {
    <<'END';
pure_all :: bin bin/hashbang ${INST_SCRIPT}/hashbang

bin :
	${MKPATH} $@

bin/hashbang :
	${CC} -o bin/hashbang src/hashbang.c

${INST_SCRIPT}/hashbang : ${INST_SCRIPT}
	rm -f ${INST_SCRIPT}/hashbang
	cp bin/hashbang $(INST_SCRIPT)/hashbang
	$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/hashbang

${INST_SCRIPT} :
	${MKPATH} $@

END
}

sub MY::installbin {''}
