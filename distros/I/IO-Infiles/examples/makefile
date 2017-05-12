.PHONY: $(shell ls)
.SILENT: 

vi      =    vi -p 'set nofoldenable'
MODULES +=  -Mblib -Mstrict -Mwarnings  -MIO::Infiles -Mv5.10

current = example_1.pl


all: example_1

example_1:
	perl -wl $(MODULES)   $@.pl
vi: w
	vim -p $(current) ../blib/lib/IO/Infiles.pm
w:
	chmod -R +w ../blib/lib/IO/
cp:
	cp ../blib/lib/IO/*  ../lib/IO/

pod:
	perldoc  ../blib/lib/IO/Infiles.pm
test:
	make -sC .. test
help:
	echo test pod
