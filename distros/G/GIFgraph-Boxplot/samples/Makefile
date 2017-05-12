PERL = perl
.SUFFIXES: .gif .pl
.SILENT:
LIB = ..
OPTIONS = -Tw

GIFS =  sample01.gif sample02.gif sample03.gif sample04.gif \
		sample05.gif

all: $(GIFS)

.pl.gif:
	$(PERL) $(OPTIONS) -I$(LIB) $<

clean:
	rm -f $(GIFS)

test:
	$(PERL) $(OPTIONS) -I$(LIB) -M$(MODULE) sample05.pl

# Dependencies

