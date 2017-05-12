mpeg2audio ?= ./mpeg2audio

CFLAGS += -I$(mpeg2audio)

OBJS-mpeg2audio := \
	$(mpeg2audio)/getbits.o \
	$(mpeg2audio)/mem.o \
	$(mpeg2audio)/mpegaudiodec.o \
	$(mpeg2audio)/utils.o
