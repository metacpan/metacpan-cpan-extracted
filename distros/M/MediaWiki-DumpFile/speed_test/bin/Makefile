CC = gcc
CCOPTS =
LIBS=-L/opt/local/lib
INCLUDES=-I/opt/local/include

all: expat libxml

clean: 
	rm -rf expat libxml iksemel *.o *.dSYM #must be recursive for Mac OS

expat: expat.c Makefile
	$(CC) $(CCOPTS) $(LIBS) $(INCLUDES) -o expat -lexpat expat.c 

libxml: libxml.c Makefile
	$(CC) $(CCOPTS) $(LIBS) $(INCLUDES) `xml-config --cflags` `xml-config --libs` -o libxml libxml.c
	
iksemel: iksemel.c Makefile
	$(CC) $(CCOPTS) $(LIBS) $(INCLUDES) -o iksemel -liksemel iksemel.c

naive: naive.c Makefile
	$(CC) $(CCOPTS) $(LIBS) $(INCLUDES) -m64 -g -o naive naive.c