first: all

#-----------

CFLAGS += -Wall -I..

all: uri_tables.h

encode.o: encode.c
	cc $(CFLAGS) -c -o$@ $^

encode: encode.o
	cc -Wall -o$@ $^

uri_tables.h: encode
	./encode > uri_tables.h

clean:
	rm -f encode.o
	rm -f encode
	rm -f uri_tables.h
