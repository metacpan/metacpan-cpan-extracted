CC=gcc
FLAGS=-Wall
DFLAGS=-ggdb -Wall

all: pi

test:
	./pi 0 1000 1

matrix: pi.c
	$(CC) $(FLAGS) pi.c -o $@

dmatrix: pi.c
	$(CC) $(DFLAGS) pi.c -o $@
