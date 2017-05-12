# This Makefile is for the Devel::CoreStack extension to perl.
#
# It was generated automatically by MakeMaker version
# 5.21 (Revision: 1.174) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	DISTNAME => q[Devel-CoreStack]
#	INSTALLDIRS => q[perl]
#	NAME => q[Devel::CoreStack]
#	VERSION_FROM => q[lib/Devel/CoreStack.pm]
#	clean => { FILES=>q[t/core] }
#	dist => { COMPRESS=>q[gzip -9f], SUFFIX=>q[gz] }
#	linkext => { LINKTYPE=>q[] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /opt/gnu/lib/perl5/sparc-solaris/5.002/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = ar
CC = gcc
CCCDLFLAGS = -fpic
CCDLFLAGS =  
DLEXT = so
DLSRC = dl_dlopen.xs
LD = gcc
LDDLFLAGS = -G -L/usr/local/lib -L/opt/gnu/lib
LDFLAGS =  -L/usr/local/lib -L/opt/gnu/lib
LIBC = /lib/libc.so
LIB_EXT = .a
OBJ_EXT = .o
RANLIB = :
SITELIBEXP = /opt/gnu/lib/perl5/site_perl
SITEARCHEXP = /opt/gnu/lib/perl5/site_perl/sparc-solaris
SO = so


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
NAME = Devel::CoreStack
DISTNAME = Devel-CoreStack
NAME_SYM = Devel_CoreStack
VERSION = 1.3
VERSION_SYM = 1_3
XS_VERSION = 1.3
INST_LIB = ./blib/lib
INST_ARCHLIB = ./blib/arch
INST_EXE = ./blib/bin
PREFIX = /opt/gnu
INSTALLDIRS = perl
INSTALLPRIVLIB = $(PREFIX)/lib/perl5
INSTALLARCHLIB = $(PREFIX)/lib/perl5/sparc-solaris/5.002
INSTALLSITELIB = $(PREFIX)/lib/perl5/site_perl
INSTALLSITEARCH = $(PREFIX)/lib/perl5/site_perl/sparc-solaris
INSTALLBIN = $(PREFIX)/bin
PERL_LIB = /opt/gnu/lib/perl5
PERL_ARCHLIB = /opt/gnu/lib/perl5/sparc-solaris/5.002
SITELIBEXP = /opt/gnu/lib/perl5/site_perl
SITEARCHEXP = /opt/gnu/lib/perl5/site_perl/sparc-solaris
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /opt/gnu/lib/perl5/sparc-solaris/5.002/CORE
PERL = /opt/gnu/bin/perl
FULLPERL = /opt/gnu/bin/perl

VERSION_MACRO = VERSION
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"

MAKEMAKER = $(PERL_LIB)/ExtUtils/MakeMaker.pm
MM_VERSION = 5.21
MM_REVISION = 

# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = Devel/CoreStack
BASEEXT = CoreStack
ROOTEXT = /Devel
DLBASE = $(BASEEXT)
VERSION_FROM = lib/Devel/CoreStack.pm
OBJECT = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES= 
C_FILES = 
O_FILES = 
H_FILES = 
MAN1PODS = 
MAN3PODS = lib/Devel/CoreStack.pm
INST_MAN1DIR = ./blib/man1
INSTALLMAN1DIR = $(PREFIX)/man/man1
MAN1EXT = 1
INST_MAN3DIR = ./blib/man3
INSTALLMAN3DIR = $(PREFIX)/lib/perl5/man/man3
MAN3EXT = 3

# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C .cpp .cxx .cc $(OBJ_EXT)

# Nick wanted to get rid of .PRECIOUS. I don't remember why. I seem to recall, that
# some make implementations will delete the Makefile when we rebuild it. Because
# we call false(1) when we rebuild it. So make(1) is not completely wrong when it
# does so. Our milage may vary.
# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext manifest

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)/Config.pm $(PERL_INC)/config.h $(VERSION_FROM)

# Where to put things:
INST_LIBDIR     = $(INST_LIB)$(ROOTEXT)
INST_ARCHLIBDIR = $(INST_ARCHLIB)$(ROOTEXT)

INST_AUTODIR      = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR  = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC  =
INST_DYNAMIC =
INST_BOOT    =

EXPORT_LIST = 

PERL_ARCHIVE = 

INST_PM = $(INST_LIB)/Devel/CoreStack.pm


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker tool_autosplit section:

# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'use AutoSplit;autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'


# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = /opt/gnu/lib/perl5/ExtUtils
XSUBPP = $(XSUBPPDIR)/xsubpp
XSPROTOARG = 
XSUBPPDEPS = $(XSUBPPDIR)/typemap
XSUBPPARGS = -typemap $(XSUBPPDIR)/typemap


# --- MakeMaker tools_other section:

SHELL = /bin/sh
LD = gcc
TOUCH = touch
CP = cp
MV = mv
RM_F  = rm -f
RM_RF = rm -rf
CHMOD = chmod
UMASK_NULL = umask 0

# The following is a portable way to say mkdir -p
# To see which directories are created, change the if 0 to if 1
MKPATH = $(PERL) -wle '$$"="/"; foreach $$p (@ARGV){' \
-e 'next if -d $$p; my(@p); foreach(split(/\//,$$p)){' \
-e 'push(@p,$$_); next if -d "@p/"; print "mkdir @p" if 0;' \
-e 'mkdir("@p",0777)||die $$! } } exit 0;'

# This helps us to minimize the effect of the .exists files A yet
# better solution would be to have a stable file in the perl
# distribution with a timestamp of zero. But this solution doesn't
# need any changes to the core distribution and works with older perls
EQUALIZE_TIMESTAMP = $(PERL) -we 'open F, ">$$ARGV[1]"; close F;' \
-e 'utime ((stat("$$ARGV[0]"))[8,9], $$ARGV[1])'

# Here we warn users that an old packlist file was found somewhere,
# and that they should call some uninstall routine
WARN_IF_OLD_PACKLIST = $(PERL) -we 'exit unless -f $$ARGV[0];' \
-e 'print "WARNING: I have found an old package in\n";' \
-e 'print "\t$$ARGV[0].\n";' \
-e 'print "Please make sure the two installations are not conflicting\n";'

MOD_INSTALL = $(PERL) -I$(INST_LIB) -MExtUtils::Install \
-e 'install({@ARGV},1);'

DOC_INSTALL = $(PERL) -e '$$\="\n\n";print "=head3 ", scalar(localtime), ": C<", shift, ">";' \
-e 'print "=over 4";' \
-e 'while ($$key = shift and $$val = shift){print "=item *";print "C<$$key: $$val>";}' \
-e 'print "=back";'

UNINSTALL =   $(PERL) -MExtUtils::Install \
-e 'uninstall($$ARGV[0],1);'



# --- MakeMaker dist section:

DISTVNAME = $(DISTNAME)-$(VERSION)
TAR  = tar
TARFLAGS = cvf
COMPRESS = gzip -9f
SUFFIX = gz
SHAR = shar
PREOP = @true
POSTOP = @true
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = INSTALLPRIVLIB="$(INSTALLPRIVLIB)"\
	INSTALLARCHLIB="$(INSTALLARCHLIB)"\
	INSTALLBIN="$(INSTALLBIN)"\
	INSTALLMAN1DIR="$(INSTALLMAN1DIR)"\
	INSTALLMAN3DIR="$(INSTALLMAN3DIR)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	INSTALLSITELIB="$(INSTALLSITELIB)"\
	INSTALLSITEARCH="$(INSTALLSITEARCH)"\
	INSTALLDIRS="$(INSTALLDIRS)"


# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:

all ::	config $(INST_PM) subdirs linkext manifypods

subdirs :: $(MYEXTLIB)



config :: Makefile $(INST_LIBDIR)/.exists

config :: $(INST_ARCHAUTODIR)/.exists

config :: $(INST_AUTODIR)/.exists

config :: Version_check


$(INST_AUTODIR)/.exists :: /opt/gnu/lib/perl5/sparc-solaris/5.002/CORE/perl.h
	@$(MKPATH) $(INST_AUTODIR)
	@$(EQUALIZE_TIMESTAMP) $(PERL) $(INST_AUTODIR)/.exists
	-@$(CHMOD) 755 $(INST_AUTODIR)

$(INST_LIBDIR)/.exists :: /opt/gnu/lib/perl5/sparc-solaris/5.002/CORE/perl.h
	@$(MKPATH) $(INST_LIBDIR)
	@$(EQUALIZE_TIMESTAMP) $(PERL) $(INST_LIBDIR)/.exists
	-@$(CHMOD) 755 $(INST_LIBDIR)

$(INST_ARCHAUTODIR)/.exists :: /opt/gnu/lib/perl5/sparc-solaris/5.002/CORE/perl.h
	@$(MKPATH) $(INST_ARCHAUTODIR)
	@$(EQUALIZE_TIMESTAMP) $(PERL) $(INST_ARCHAUTODIR)/.exists
	-@$(CHMOD) 755 $(INST_ARCHAUTODIR)

config :: $(INST_MAN3DIR)/.exists


$(INST_MAN3DIR)/.exists :: /opt/gnu/lib/perl5/sparc-solaris/5.002/CORE/perl.h
	@$(MKPATH) $(INST_MAN3DIR)
	@$(EQUALIZE_TIMESTAMP) $(PERL) $(INST_MAN3DIR)/.exists
	-@$(CHMOD) 755 $(INST_MAN3DIR)

help:
	perldoc ExtUtils::MakeMaker

Version_check:
	@$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		-MExtUtils::MakeMaker=Version_check \
		-e 'Version_check("$(MM_VERSION)")'


# --- MakeMaker linkext section:

linkext :: 



# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make dynamic"
dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)



# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make static"
static :: Makefile $(INST_STATIC) $(INST_PM)



# --- MakeMaker static_lib section:


# --- MakeMaker installpm section:
inst_pm :: $(INST_PM)


# installpm: lib/Devel/CoreStack.pm => $(INST_LIB)/Devel/CoreStack.pm, splitlib=$(INST_LIB)

$(INST_LIB)/Devel/CoreStack.pm: lib/Devel/CoreStack.pm Makefile $(INST_LIB)/Devel/.exists $(INST_ARCHAUTODIR)/.exists
	@rm -f $@
	$(UMASK_NULL) && cp lib/Devel/CoreStack.pm $@
	@$(AUTOSPLITFILE) $@ $(INST_LIB)/auto

$(INST_LIB)/Devel/.exists :: /opt/gnu/lib/perl5/sparc-solaris/5.002/CORE/perl.h
	@$(MKPATH) $(INST_LIB)/Devel
	@$(EQUALIZE_TIMESTAMP) $(PERL) $(INST_LIB)/Devel/.exists
	-@$(CHMOD) 755 $(INST_LIB)/Devel



# --- MakeMaker manifypods section:
POD2MAN_EXE = /opt/gnu/bin/pod2man
POD2MAN = $(PERL) -we '%m=@ARGV;for (keys %m){' \
-e 'next if -e $$m{$$_} && -M $$m{$$_} < -M $$_ && -M $$m{$$_} < -M "Makefile";' \
-e 'print "Manifying $$m{$$_}\n";' \
-e 'system("$$^X \"-I$(PERL_ARCHLIB)\" \"-I$(PERL_LIB)\" $(POD2MAN_EXE) $$_>$$m{$$_}")==0 or warn "Couldn\047t install $$m{$$_}\n";' \
-e 'chmod 0644, $$m{$$_} or warn "chmod 644 $$m{$$_}: $$!\n";}'

manifypods : lib/Devel/CoreStack.pm
	@$(POD2MAN) \
	lib/Devel/CoreStack.pm \
	$(INST_MAN3DIR)/Devel::CoreStack.$(MAN3EXT)

# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	-rm -rf t/core ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all perlmain.c mon.out core so_locations *~ */*~ */*/*~ *$(OBJ_EXT) *$(LIB_EXT) perl.exe $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def $(BASEEXT).exp
	-mv Makefile Makefile.old 2>/dev/null


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	rm -rf $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	rm -f $(INST_DYNAMIC) $(INST_BOOT)
	rm -f $(INST_STATIC) $(INST_PM)
	rm -rf Makefile Makefile.old


# --- MakeMaker dist_basics section:

distclean :: realclean distcheck

distcheck :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&fullcheck";' \
		-e 'fullcheck();'

skipcheck :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&skipcheck";' \
		-e 'skipcheck();'

manifest :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&mkmanifest";' \
		-e 'mkmanifest();'


# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT)

tardist : $(DISTVNAME).tar.$(SUFFIX)

$(DISTVNAME).tar.$(SUFFIX) : distdir
	$(PREOP)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

uutardist : $(DISTVNAME).tar.$(SUFFIX)
	uuencode $(DISTVNAME).tar.$(SUFFIX) \
		$(DISTVNAME).tar.$(SUFFIX) > \
		$(DISTVNAME).tar.$(SUFFIX).uu

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker dist_dir section:

distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "/mani/";' \
		-e 'manicopy(maniread(),"$(DISTVNAME)", "$(DIST_CP)");'


# --- MakeMaker dist_test section:

disttest : distdir
	cd $(DISTVNAME) && $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) Makefile.PL
	cd $(DISTVNAME) && $(MAKE)
	cd $(DISTVNAME) && $(MAKE) test


# --- MakeMaker dist_ci section:

ci :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&maniread";' \
		-e '@all = keys %{ maniread() };' \
		-e 'print("Executing $(CI) @all\n"); system("$(CI) @all");' \
		-e 'print("Executing $(RCS_LABEL) ...\n"); system("$(RCS_LABEL) @all");'


# --- MakeMaker install section:

install :: all pure_install doc_install

install_perl :: all pure_perl_install doc_perl_install

install_site :: all pure_site_install doc_site_install

install_ :: install_site
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_install :: pure_$(INSTALLDIRS)_install

doc_install :: doc_$(INSTALLDIRS)_install
	@echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod

pure__install : pure_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	@$(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(INSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(INSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(INSTALLARCHLIB) \
		$(INST_EXE) $(INSTALLBIN) \
		$(INST_MAN1DIR) $(INSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(INSTALLMAN3DIR)
	@$(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install ::
	@$(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(INSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(INSTALLSITELIB) \
		$(INST_ARCHLIB) $(INSTALLSITEARCH) \
		$(INST_EXE) $(INSTALLBIN) \
		$(INST_MAN1DIR) $(INSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(INSTALLMAN3DIR)
	@$(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

doc_perl_install ::
	@$(DOC_INSTALL) \
		"$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(INSTALLARCHLIB)/perllocal.pod

doc_site_install ::
	@$(DOC_INSTALL) \
		"Module $(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(INSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs

uninstall_from_perldirs ::
	@$(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	@$(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:


# --- MakeMaker perldepend section:

PERL_HDRS = $(PERL_INC)/EXTERN.h $(PERL_INC)/INTERN.h \
    $(PERL_INC)/XSUB.h	$(PERL_INC)/av.h	$(PERL_INC)/cop.h \
    $(PERL_INC)/cv.h	$(PERL_INC)/dosish.h	$(PERL_INC)/embed.h \
    $(PERL_INC)/form.h	$(PERL_INC)/gv.h	$(PERL_INC)/handy.h \
    $(PERL_INC)/hv.h	$(PERL_INC)/keywords.h	$(PERL_INC)/mg.h \
    $(PERL_INC)/op.h	$(PERL_INC)/opcode.h	$(PERL_INC)/patchlevel.h \
    $(PERL_INC)/perl.h	$(PERL_INC)/perly.h	$(PERL_INC)/pp.h \
    $(PERL_INC)/proto.h	$(PERL_INC)/regcomp.h	$(PERL_INC)/regexp.h \
    $(PERL_INC)/scope.h	$(PERL_INC)/sv.h	$(PERL_INC)/unixish.h \
    $(PERL_INC)/util.h	$(PERL_INC)/config.h



# --- MakeMaker makefile section:

# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile :	Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@mv Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean >/dev/null 2>&1 || true
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL 
	@echo ">>> Your Makefile has been rebuilt. <<<"
	@echo ">>> Please rerun the make command.  <<<"; false


# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /opt/gnu/bin/perl

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) static $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	@echo Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)

test :: $(TEST_TYPE)
	@echo 'No tests defined for $(NAME) extension.'

test_dynamic :: all

test_ : test_dynamic

test_static :: test_dynamic


# --- MakeMaker postamble section:


# --- MakeMaker selfdocument section:


# End.
