use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'cpr',
	      VERSION => '0.30',
	      clean => {FILES => 'cpr cpr.c'},
	     );

sub MY::top_targets {
    <<'END';

.SUFFIXES: .plc .c $(OBJ_EXT)

PM_TO_BLIB = cpr$(EXE_EXT) $(INST_BIN)/cpr$(EXE_EXT)

.plc.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $*.plc $(INSTALLBIN) > tmp.c && $(MV) tmp.c $*.c

.c$(OBJ_EXT):
	$(CC) -c $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c

all: cpr$(EXE_EXT) pm_to_blib

cpr$(EXE_EXT): cpr.c cpr$(OBJ_EXT)
	$(LD) -o $@ cpr$(OBJ_EXT)

pure_all:

END
}
