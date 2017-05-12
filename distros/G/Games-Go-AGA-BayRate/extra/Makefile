

CC=gcc
CFLAGS=-I.
# DEPS = test.h
LIBS=-lgsl

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

f_test: f_test.o
	gcc -o $@ $^ $(CFLAGS) $(LIBS)

fdf_test: fdf_test.o
	gcc -o $@ $^ $(CFLAGS) $(LIBS)

