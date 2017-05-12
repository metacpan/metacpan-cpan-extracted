.PHONY: $(shell ls)
.SILENT: 


# 01_main.t   02_reading.t     03_reading.t
# pod.t       pod-coverage.t   distribution.t


current = 01c_coverage.t
current = 01s_spelling.t

all: $(current)
#all: distribution.t



 MODULES  =  -MData::Dumper 
 MODULES +=  -MTest::Exception
 MODULES +=  -MTest::More   -MIO::Infiles
#MODULES +=  -MCarp  -MParams::Validate=':all'

1* 2* 3* d* I* 0* p*:
	perl -wl -Mstrict -Mblib  $(MODULES)   $@  
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
