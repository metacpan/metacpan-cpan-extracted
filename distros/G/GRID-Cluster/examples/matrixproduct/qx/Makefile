CC=gcc
FLAGS=-Wall
DFLAGS=-ggdb -Wall

all: matrix

test:
	./matrix p1.dat p2.dat

matrix: matrix.c
	$(CC) $(FLAGS) matrix.c -o $@

dmatrix: matrix.c
	$(CC) $(DFLAGS) matrix.c -o $@

