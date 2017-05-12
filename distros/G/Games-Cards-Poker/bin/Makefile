# makefile for pokr
# Author: Pip Stuart <Pip@CPAN.Org>
#CFLAGS  = -s -O2 -DLINUX
CFLAGS  = -s -O6 -mcpu=pentium -DLINUX
NAME    = pokr
LNAME   = pokr
INSTALL = install

pokr: pokr.o
	cc $(CFLAGS) -o $(NAME) pokr.o $(LIBS)
	@echo "### Compiling of pokr complete! ###"

pokr.o: pokr.c
	@echo "####### Now compiling pokr! #######"
	cc $(CFLAGS) -c pokr.c

clean:
	rm *.o pokr

install: $(NAME)
	$(INSTALL) -m 775 $(NAME) /usr/local/bin/

tar:
	cd .. && tar cf - $(LNAME)/ | gzip -9 > $(LNAME)/$(LNAME).tgz
