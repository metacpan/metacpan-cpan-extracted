# $Id: Makefile.am,v 1.12.2.2 2011/06/20 03:43:39 ak Exp $
# Copyright (C) 2013 azumakuniyuki
SYSTEMNAME = Haineko
SYSVERSION = 0.2.16
SUBDIRS = bin etc lib libexec

.PHONY: clean
all-am: Makefile
install-am: subdirectories install-depend message

clean-am:
	rm -f ./*~ ./*.bak ./*.tmp 
	find . -name '*.rej' -type f -exec rm -f {} \;
	find . -name '*.rej.orig' -type f -exec rm -f {} \;
	rm -fr ./.temp ./.test

distclean-am: clean-am
	rm -fr ./dist

depend:
	test -d ./dist || mkdir -p ./dist
	$(CPANM) -f -L ./dist --installdeps .

install-depend:
	test -d ./dist/lib/perl5 && cp -Rp ./dist/lib/perl5 @libdir@/ || :
	test -d @libexecdir@ || mkdir -p @libexecdir@

test:
	LANG=C $(PROVE) -I@prefix@/lib/perl5 t/

subdirectories:
	mkdir -pm 0755 @prefix@/run
	mkdir -pm 0755 @prefix@/log
	mkdir -pm 0755 @prefix@/tmp

message:
	@echo "-----------------------------------------------------------------------------"
	@echo " $(SYSTEMNAME) $(SYSVERSION) "
	@echo "-----------------------------------------------------------------------------"
	@echo " Setting up $(SYSTEMNAME)"
	@echo
	@echo "  1. Edit @sysconfdir@/haineko.cf and other routing table files"
	@echo "  2. Start Haineko server"
	@echo "     > cd @prefix@"
	@echo "     > export PERL5LIB=@libdir@/perl5"
	@echo "     > plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi"
	@echo "     OR"
	@echo "     > ./bin/hainekoctl help"
	@echo "     > ./bin/hainekoctl start -d"
	@echo "  3. Connect http://127.0.0.1:2794/submit"
	@echo
	@echo "-----------------------------------------------------------------------------"
	@echo " To show this screen, type 'make message' and hit 'Return' key"
	@echo "-----------------------------------------------------------------------------"
	@echo

