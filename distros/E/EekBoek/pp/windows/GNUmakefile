# GNUmakefile for MS Windows + Strawberry Perl + wxWidgets 3.0.

# Needed for the environment settings.
# .ONESHELL :

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
RES    := ..\..\lib\EB\res
PP := pp -u

all : clean ebshell ebwxshell

.PHONY :: ebshell ebwxshell

ebshell : ebshell.exe

ebwxshell : ebwxshell.exe

# PAR_VERBATIM=1 prevents POD filtering. ChordPro/Config.pm needs POD!
ebshell.exe : ebshell.pp
	${PP} --output=ebshell.exe @ebshell.pp ${SCRIPT}/ebshell.pl

# For wxWidgets, explicit libraries are specified in ebwxshell.pp and the
# PATH must be set accordingly.
# To set PATH from the makefile, we need .ONESHELL pseudo target above.

ebwxshell.exe : ebshell.pp ebwxshell.pp
	${PP} --output=ebwxshell.exe @ebwxshell.pp ${SCRIPT}/ebwxshell.pl

clean ::
	del eb*shell.exe
	del *.pp.deps

#### NOTE: THIS MAY NEED ADJUSTMENT FOR YOUR SYSTEM
ISC := 	"C:\Program Files (x86)\Inno Setup 6\Compil32.exe"
ISCC := "C:\Program Files (x86)\Inno Setup 6\iscc.exe"

.PHONY :: iss_par
iss_par :: ebshell.exe ebwxshell.exe innosetup_par.iss ebshellinst.bmp
	copy ${RES}\icons\ebshell.ico .
	perl vfix.pl innosetup_par.iss
	${ISC} /cc innosetup_par.iss

PLIBS := C:\Strawberry\perl\bin
CLIBS := C:\Strawberry\c\bin
DEST  := build

.PHONY :: ppl
ppl : clean ebshell.exe ebwxshell.exe unpack copy_coredll loaders

# Unpack the pp generated kits.
.PHONY :: unpack
unpack :
	perl ..\pp2ppl.pl --quiet --dest="${DEST}" ebshell.exe
	perl ..\pp2ppl.pl --quiet --dest="${DEST}" ebwxshell.exe
	copy "${RES}\Wx\icons\eb.ico" "${DEST}"
	move "${DEST}\res" "${DEST}\lib\EB"

# The core DLLs needed for Strawberry perl. The Wx libs have been unpacked already.
copy_coredll :
	copy "${CLIBS}\libgcc_s_seh-1.dll"  "${DEST}"
	copy "${CLIBS}\libstdc++-6.dll"     "${DEST}"
	copy "${CLIBS}\libwinpthread-1.dll" "${DEST}"
	copy "${PLIBS}\perl530.dll"         "${DEST}"

# Portable Perl Loaders

PFX := "\"script\\\""
CC := gcc -Wall -Wstrict-prototypes -O2 -s -mms-bitfields -fwrapv -DSCRIPTPREFIX=${PFX}

.PHONY :: loaders
loaders : "${DEST}\ebwxshell.exe" "${DEST}\ebshell.exe"

"${DEST}\ebwxshell.exe" : ppl.c ebwxshell.rc
	perl vfix.pl ebwxshell.rc
	windres ebwxshell.rc ppl.o
	${CC} -mwindows -o "${DEST}\ebwxshell.exe" ppl.c ppl.o

"${DEST}\ebshell.exe" : ppl.c ebshell.rc
	perl vfix.pl ebshell.rc
	windres ebshell.rc ppl.o
	${CC} -mconsole -o "${DEST}\ebshell.exe" ppl.c ppl.o

# And finally, the installer.

.PHONY :: iss
iss : "${DEST}\ebwxshell.exe" innosetup.iss
	perl vfix.pl
	${ISCC} innosetup.iss

clean ::
	-rmdir /q/s "${DEST}"
