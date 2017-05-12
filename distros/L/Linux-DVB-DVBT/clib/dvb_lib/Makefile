CFLAGS   := -ggdb
ifdef DEBUG
CFLAGS   += -O0
else
CFLAGS   += -O3
endif
CFLAGS   += -pedantic
CFLAGS   += -std=gnu99
CFLAGS   += -fPIC
CFLAGS   += -I.
CFLAGS   += -D_LARGEFILE_SOURCE
CFLAGS   += -D_FILE_OFFSET_BITS=64
CFLAGS   += -D_GNU_SOURCE
CFLAGS   += -DHAVE_DVB

# Add lots of extra checks
CFLAGS += -Wall -Werror -Wpointer-arith -Wcast-qual -Wwrite-strings -Waggregate-return -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations 
CFLAGS += -Wredundant-decls -Wnested-externs 

ifdef TESTDEF
	CFLAGS += -D $(TESTDEF)
endif
ifdef PROFILE_STREAM
	CFLAGS += -DPROFILE_STREAM
endif

# libdvb_lib
libdvb_lib := .
include $(libdvb_lib)/Subdir.mk

# libng
libng := ../libng
include $(libng)/Subdir.mk

OBJS := \
$(OBJS-libdvb_lib) \
$(OBJS-libng)


libdvb_lib.a: $(OBJS)
	$(AR) cr libdvb_lib.a $(OBJS)
	ranlib libdvb_lib.a

clean::
	rm -f $(libdvb_lib)/*.a
	rm -f $(libdvb_lib)/*.o
	rm -f $(libng)/*.a
	rm -f $(libng)/*.o

