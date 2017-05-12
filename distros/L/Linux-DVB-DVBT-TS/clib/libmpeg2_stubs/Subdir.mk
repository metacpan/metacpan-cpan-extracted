libmpeg2_stubs ?= .

CFLAGS += -I$(libmpeg2_stubs) -I$(libmpeg2_stubs)/include

OBJS-libmpeg2 := \
	$(libmpeg2_stubs)/mpeg2_stubs.o
