libmpeg2 ?= .

CFLAGS += -I$(libmpeg2) -I$(libmpeg2)/convert -I$(libmpeg2)/include

OBJS-libmpeg2 := \
	$(libmpeg2)/alloc.o \
	$(libmpeg2)/cpu_accel.o \
	$(libmpeg2)/cpu_state.o \
	$(libmpeg2)/decode.o \
	$(libmpeg2)/header.o \
	$(libmpeg2)/idct.o \
	$(libmpeg2)/idct_mmx.o \
	$(libmpeg2)/motion_comp.o \
	$(libmpeg2)/motion_comp_mmx.o \
	$(libmpeg2)/slice.o \
	$(libmpeg2)/src/dump_state.o \
	$(libmpeg2)/convert/rgb.o \
	$(libmpeg2)/convert/rgb_mmx.o \
	$(libmpeg2)/convert/uyvy.o
