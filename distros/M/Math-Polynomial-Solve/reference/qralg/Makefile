
FFLAGS = -u -g
F77 = f77

.f.o :; $(F77) -c $(FFLAGS) $<
#
MAKEFILE = Makefile
#
SRCS = test.f qralg.f
#
OBJS = test.o qralg.o
#
PROGRAMS = a.out
#
all : $(PROGRAMS)
#
LOADER  = $(F77)
LDFLAGS = -g

a.out : $(OBJS); 
	@$(LOADER) $(LDFLAGS) -o $@ $(OBJS)
#
clean :;
	@-rm $(OBJS) $(PROGRAMS);
