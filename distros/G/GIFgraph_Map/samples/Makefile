PERL = perl
.SUFFIXES: .gif .pl .html
.SILENT:
LIB = ..
OPTIONS = -T

GIFS =  sample11.gif sample12.gif sample13.gif sample14.gif \
		sample15.gif sample16.gif \
		sample31.gif \
		sample41.gif \
		sample51.gif sample52.gif sample53.gif

all: $(GIFS)

.pl.gif:
	$(PERL) $(OPTIONS) -I$(LIB) $<

clean:
	rm -f *.gif sample*.html

test:
	$(PERL) sample51.pl
