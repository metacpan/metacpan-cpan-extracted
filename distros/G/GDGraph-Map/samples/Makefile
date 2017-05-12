PERL = perl
.SUFFIXES: .png .pl .html
.SILENT:
LIB = ../lib
OPTIONS = -T -I$LIB

GIFS =  sample11.png sample12.png sample13.png sample14.png \
	sample15.png sample16.png \
	sample31.png \
	sample41.png \
	sample51.png sample52.png \
	sample91.png sample92.png sample93.png

all: $(GIFS)

.pl.png:
	$(PERL) $(OPTIONS) -I$(LIB) $<

clean:
	rm -f *.png sample*.html

