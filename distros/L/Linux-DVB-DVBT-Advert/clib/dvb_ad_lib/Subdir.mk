ifndef libdvb_ad_lib
libdvb_ad_lib := .
endif

CFLAGS += -I$(libdvb_ad_lib)

OBJS-libdvb_ad_lib := \
 $(libdvb_ad_lib)/detect/advert.o \
 $(libdvb_ad_lib)/detect/ad_debug.o \
 $(libdvb_ad_lib)/detect/ad_audio.o \
 $(libdvb_ad_lib)/detect/ad_frame.o \
 $(libdvb_ad_lib)/detect/ad_logo.o \
 $(libdvb_ad_lib)/detect/ad_file.o
