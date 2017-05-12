libdvb_lib ?= .

CFLAGS += -I$(libdvb_lib)

OBJS-libdvb_lib := \
	$(libdvb_lib)/struct-dvb.o \
	$(libdvb_lib)/dvb_tune.o \
	$(libdvb_lib)/dvb_stream.o \
	$(libdvb_lib)/dvb_epg.o \
	$(libdvb_lib)/dvb_scan.o \
	$(libdvb_lib)/dvb_debug.o \
	$(libdvb_lib)/dvb_lib.o 

