OBJS = src/ciphers/aes/aes.o src/misc/crypt/crypt_argchk.o src/misc/compare_testvector.o src/misc/zeromem.o

LIB_EXT    =.a
OBJ_EXT    =.o
PERL       =perl
RANLIB     =ranlib
AR         =ar
ARFLAGS    =cr
RM_F       =$(PERL) -MExtUtils::Command -e rm_f --

libonlyaes$(LIB_EXT): $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)
	$(RANLIB) $@

clean:
	$(RM_F) $(OBJS) libonlyaes$(LIB_EXT)

#this is necessary for compatibility with BSD make (namely on OpenBSD)
.SUFFIXES: .o .c

.c$(OBJ_EXT):
	$(CC) -Isrc/headers -DLTC_SOURCE -DLTC_NO_TEST -DLTC_NO_PROTOTYPES -DLTM_DESC $(CFLAGS) -DARGTYPE=4 -c $< -o $@
