# This Makefile is for the PDL::Meschach extension to perl.
#
# It was generated automatically by MakeMaker version
# 5.34 (Revision: 1.202) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	DEFINE => q[]
#	DISTNAME => q[Meschach]
#	INC => q[-Imeschach-1.2 -I../../PDL/Core]
#	LIBS => [q[-Lmeschach-1.2 -lmes], q[-lm]]
#	NAME => q[PDL::Meschach]
#	NORECURS => q[true]
#	OBJECT => q[mespdl.o p_funcs.o Meschach.o]
#	PM => { Meschach.pm=>q[$(INST_LIBDIR)/Meschach.pm] }
#	TYPEMAPS => [q[../../PDL/Core/typemap.pdl]]
#	VERSION_FROM => q[Meschach.pm]
#	clean => { FILES=>q[mespdl.o p_funcs.o Meschach.o] }
#	dist => { COMPRESS=>q[gzip -9f] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/local/lib/perl5/next/5.003/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = ar
CC = gcc
CCCDLFLAGS =  
CCDLFLAGS =  
DLEXT = so
DLSRC = dl_next.xs
LD = ld
LDDLFLAGS = -r -L/usr/local/lib
LDFLAGS = -u libsys_s -L/usr/local/lib
LIBC = /lib/libsys_s.a
LIB_EXT = .a
OBJ_EXT = .o
RANLIB = sleep 5; /bin/ranlib
SO = so


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
NAME = PDL::Meschach
DISTNAME = Meschach
NAME_SYM = PDL_Meschach
VERSION = 0.03
VERSION_SYM = 0_03
XS_VERSION = 0.03
INST_BIN = ./blib/bin
INST_EXE = ./blib/script
INST_LIB = ./blib/lib
INST_ARCHLIB = ./blib/arch
INST_SCRIPT = ./blib/script
PREFIX = /usr/local
INSTALLDIRS = site
INSTALLPRIVLIB = $(PREFIX)/lib/perl5
INSTALLARCHLIB = $(PREFIX)/lib/perl5/next/5.003
INSTALLSITELIB = $(PREFIX)/lib/perl5/site_perl
INSTALLSITEARCH = $(PREFIX)/lib/perl5/site_perl/next
INSTALLBIN = $(PREFIX)/bin
INSTALLSCRIPT = $(PREFIX)/bin
PERL_LIB = /usr/local/lib/perl5
PERL_ARCHLIB = /usr/local/lib/perl5/next/5.003
SITELIBEXP = /usr/local/lib/perl5/site_perl
SITEARCHEXP = /usr/local/lib/perl5/site_perl/next
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/local/lib/perl5/next/5.003/CORE
PERL = /usr/bin/perl
FULLPERL = /usr/bin/perl

VERSION_MACRO = VERSION
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"

MAKEMAKER = /usr/local/lib/perl5/ExtUtils/MakeMaker.pm
MM_VERSION = 5.34

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)  !!! Deprecated from MM 5.32  !!!
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = PDL/Meschach
BASEEXT = Meschach
PARENT_NAME = PDL::
DLBASE = $(BASEEXT)
VERSION_FROM = Meschach.pm
INC = -Imeschach-1.2 -I../../PDL/Core
DEFINE = 
OBJECT = mespdl$(OBJ_EXT) p_funcs$(OBJ_EXT) Meschach$(OBJ_EXT)
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES= Meschach.xs
C_FILES = Meschach.c \
	mespdl.c \
	mespdl.old.c \
	p_funcs.c
O_FILES = Meschach.o \
	mespdl.o \
	mespdl.old.o \
	p_funcs.o
H_FILES = Meschach.h \
	mespdl.h \
	p_funcs.h
MAN1PODS = 
MAN3PODS = 
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
CONFIGDEP = $(PERL_ARCHLIB)/Config.pm $(PERL_INC)/config.h

# Where to put things:
INST_LIBDIR      = $(INST_LIB)/PDL
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/PDL

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC  = $(INST_ARCHAUTODIR)/$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)/$(DLBASE).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)/$(BASEEXT).bs

EXPORT_LIST = 

PERL_ARCHIVE = 

TO_INST_PM = Meschach.pm

PM_TO_BLIB = Meschach.pm \
	$(INST_LIBDIR)/Meschach.pm


# --- MakeMaker tool_autosplit section:

# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'use AutoSplit;autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'


# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = /usr/local/lib/perl5/ExtUtils
XSUBPP = $(XSUBPPDIR)/xsubpp
XSPROTOARG = 
XSUBPPDEPS = $(XSUBPPDIR)/typemap ../../PDL/Core/typemap.pdl
XSUBPPARGS = -typemap $(XSUBPPDIR)/typemap -typemap ../../PDL/Core/typemap.pdl


# --- MakeMaker tools_other section:

SHELL = /bin/sh
CHMOD = chmod
CP = cp
LD = ld
MV = mv
NOOP = sh -c true
RM_F = rm -f
RM_RF = rm -rf
TOUCH = touch
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

UNINST=0
VERBINST=1

MOD_INSTALL = $(PERL) -I$(INST_LIB) -I$(PERL_LIB) -MExtUtils::Install \
-e 'install({@ARGV},"$(VERBINST)",0,"$(UNINST)");'

DOC_INSTALL = $(PERL) -e '$$\="\n\n";print "=head3 ", scalar(localtime), ": C<", shift, ">";' \
-e 'print "=over 4";' \
-e 'while (defined($$key = shift) and defined($$val = shift)){print "=item *";print "C<$$key: $$val>";}' \
-e 'print "=back";'

UNINSTALL =   $(PERL) -MExtUtils::Install \
-e 'uninstall($$ARGV[0],1);'



# --- MakeMaker dist section:
# COMPRESS, gzip -9f

DISTVNAME = $(DISTNAME)-$(VERSION)
TAR  = tar
TARFLAGS = cvf
ZIP  = zip
ZIPFLAGS = -r
COMPRESS = gzip -9f
SUFFIX = .Z
SHAR = shar
PREOP = @$(NOOP)
POSTOP = @$(NOOP)
TO_UNIX = @$(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:

CCFLAGS = -DUSE_NEXT_CTYPE -DNEXT30_NO_ATTRIBUTE -I/usr/local/include
OPTIMIZE = -O
PERLTYPE = 
LARGE = 
SPLIT = 


# --- MakeMaker const_loadlibs section:

# PDL::Meschach might depend on some other libraries:
# See ExtUtils::Liblist for details
#
EXTRALIBS = -L/etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2 -lmes
LDLOADLIBS = -L/etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2
BSLOADLIBS = /etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2/libmes.a
LD_RUN_PATH = /etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2


# --- MakeMaker const_cccmd section:
CCCMD = $(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION)

# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	OPTIMIZE="$(OPTIMIZE)"


# --- MakeMaker c_o section:

.c$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c

.C$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.C

.cpp$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cpp

.cxx$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cxx

.cc$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cc


# --- MakeMaker xs_c section:

.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >$*.tc && mv $*.tc $@


# --- MakeMaker xs_o section:

.xs$(OBJ_EXT):
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c


# --- MakeMaker top_targets section:

#all ::	config $(INST_PM) subdirs linkext manifypods

all :: pure_all manifypods
	@$(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	@$(NOOP)

subdirs :: $(MYEXTLIB)
	@$(NOOP)

config :: Makefile $(INST_LIBDIR)/.exists
	@$(NOOP)

config :: $(INST_ARCHAUTODIR)/.exists
	@$(NOOP)

config :: $(INST_AUTODIR)/.exists
	@$(NOOP)

config :: Version_check
	@$(NOOP)


$(INST_AUTODIR)/.exists :: /usr/local/lib/perl5/next/5.003/CORE/perl.h
	@$(MKPATH) $(INST_AUTODIR)
	@$(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/next/5.003/CORE/perl.h $(INST_AUTODIR)/.exists

	-@$(CHMOD) 755 $(INST_AUTODIR)

$(INST_LIBDIR)/.exists :: /usr/local/lib/perl5/next/5.003/CORE/perl.h
	@$(MKPATH) $(INST_LIBDIR)
	@$(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/next/5.003/CORE/perl.h $(INST_LIBDIR)/.exists

	-@$(CHMOD) 755 $(INST_LIBDIR)

$(INST_ARCHAUTODIR)/.exists :: /usr/local/lib/perl5/next/5.003/CORE/perl.h
	@$(MKPATH) $(INST_ARCHAUTODIR)
	@$(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/next/5.003/CORE/perl.h $(INST_ARCHAUTODIR)/.exists

	-@$(CHMOD) 755 $(INST_ARCHAUTODIR)

$(O_FILES): $(H_FILES)

help:
	perldoc ExtUtils::MakeMaker

Version_check:
	@$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		-MExtUtils::MakeMaker=Version_check \
		-e 'Version_check("$(MM_VERSION)")'


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	@$(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make dynamic"
#dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)
dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT)
	@$(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP = Meschach.bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): Makefile  $(INST_ARCHAUTODIR)/.exists
	@echo "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	@$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		-e 'use ExtUtils::Mkbootstrap;' \
		-e 'Mkbootstrap("$(BASEEXT)","$(BSLOADLIBS)");'
	@$(TOUCH) $(BOOTSTRAP)
	$(CHMOD) 644 $@

$(INST_BOOT): $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists
	@rm -rf $(INST_BOOT)
	-cp $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) 644 $@


# --- MakeMaker dynamic_lib section:

# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = :
OTHERLDFLAGS = 
INST_DYNAMIC_DEP = 

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
	LD_RUN_PATH="$(LD_RUN_PATH)" $(LD) -o $@ $(LDDLFLAGS) $(LDFROM) $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) $(EXPORT_LIST)
	$(CHMOD) 755 $@


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
#static :: Makefile $(INST_STATIC) $(INST_PM)
static :: Makefile $(INST_STATIC)
	@$(NOOP)


# --- MakeMaker static_lib section:

$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)/.exists
	$(RM_RF) $@
	$(AR) $(AR_STATIC_ARGS) $@ $(OBJECT) && $(RANLIB) $@
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld
	$(CHMOD) 755 $@


# --- MakeMaker manifypods section:

manifypods :
	@$(NOOP)


# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean section:
# FILES, mespdl.o p_funcs.o Meschach.o

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	-rm -rf Meschach.c mespdl.o p_funcs.o Meschach.o ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all perlmain.c mon.out core so_locations pm_to_blib *~ */*~ */*/*~ *$(OBJ_EXT) *$(LIB_EXT) perl.exe $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def $(BASEEXT).exp
	-mv Makefile Makefile.old 2>/dev/null


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	rm -rf $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	rm -f $(INST_DYNAMIC) $(INST_BOOT)
	rm -f $(INST_STATIC)
	rm -f $(INST_LIBDIR)/Meschach.pm
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
	@$(PERL) -le 'print "Warning: Makefile possibly out of date with $$vf" if ' \
	    -e '-e ($$vf="$(VERSION_FROM)") and -M $$vf < -M "Makefile";'

tardist : $(DISTVNAME).tar$(SUFFIX)

zipdist : $(DISTVNAME).zip

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) \
		$(DISTVNAME).tar$(SUFFIX) > \
		$(DISTVNAME).tar$(SUFFIX)_uu

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker dist_dir section:

distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Manifest=manicopy,maniread \
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
		$(INST_BIN) $(INSTALLBIN) \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
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
		$(INST_BIN) $(INSTALLBIN) \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
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

PERL_HDRS = \
$(PERL_INC)/EXTERN.h       $(PERL_INC)/gv.h           $(PERL_INC)/pp.h       \
$(PERL_INC)/INTERN.h       $(PERL_INC)/handy.h        $(PERL_INC)/proto.h    \
$(PERL_INC)/XSUB.h         $(PERL_INC)/hv.h           $(PERL_INC)/regcomp.h  \
$(PERL_INC)/av.h           $(PERL_INC)/keywords.h     $(PERL_INC)/regexp.h   \
$(PERL_INC)/config.h       $(PERL_INC)/mg.h           $(PERL_INC)/scope.h    \
$(PERL_INC)/cop.h          $(PERL_INC)/op.h           $(PERL_INC)/sv.h	     \
$(PERL_INC)/cv.h           $(PERL_INC)/opcode.h       $(PERL_INC)/unixish.h  \
$(PERL_INC)/dosish.h       $(PERL_INC)/patchlevel.h   $(PERL_INC)/util.h     \
$(PERL_INC)/embed.h        $(PERL_INC)/perl.h				     \
$(PERL_INC)/form.h         $(PERL_INC)/perly.h

$(OBJECT) : $(PERL_HDRS)

Meschach.c : $(XSUBPPDEPS)


# --- MakeMaker makefile section:

$(OBJECT) : $(FIRST_MAKEFILE)

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile : Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@mv Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean >/dev/null 2>&1 || true
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL 
	@echo ">>> Your Makefile has been rebuilt. <<<"
	@echo ">>> Please rerun the make command.  <<<"; false

# To change behavior to :: would be nice, but would break Tk b9.02
# so you find such a warning below the dist target.
#Makefile :: $(VERSION_FROM)
#	@echo "Warning: Makefile possibly out of date with $(VERSION_FROM)"


# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /usr/bin/perl

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	@echo Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE)

test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) test.pl

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERL) $(TESTDB_SW) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)

test_ : test_dynamic

test_static :: pure_all $(MAP_TARGET)
	PERL_DL_NONLAZY=1 ./$(MAP_TARGET) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) test.pl

testdb_static :: pure_all $(MAP_TARGET)
	PERL_DL_NONLAZY=1 ./$(MAP_TARGET) $(TESTDB_SW) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)



# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	@$(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" \
	"-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Install \
        -e 'pm_to_blib({qw{$(PM_TO_BLIB)}},"$(INST_LIB)/auto")'
	@$(TOUCH) $@


# --- MakeMaker selfdocument section:

# Full list of MakeMaker attribute values:
#	AR => q[ar]
#	AR_STATIC_ARGS => q[cr]
#	BASEEXT => q[Meschach]
#	BOOTDEP => q[]
#	BSLOADLIBS => q[/etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2/libmes.a]
#	C => [q[Meschach.c], q[mespdl.c], q[mespdl.old.c], q[p_funcs.c]]
#	CC => q[gcc]
#	CCCDLFLAGS => q[ ]
#	CCDLFLAGS => q[ ]
#	CCFLAGS => q[-DUSE_NEXT_CTYPE -DNEXT30_NO_ATTRIBUTE -I/usr/local/include]
#	CFLAGS => q[ CCFLAGS = -DUSE_NEXT_CTYPE -DNEXT30_NO_ATTRIBUTE -I/usr/local/include OPTIMIZE = -O PERLTYPE = LARGE = SPLIT = ]
#	CHMOD => q[chmod]
#	CONFIG => [q[ar], q[cc], q[cccdlflags], q[ccdlflags], q[dlext], q[dlsrc], q[ld], q[lddlflags], q[ldflags], q[libc], q[lib_ext], q[obj_ext], q[ranlib], q[sitelibexp], q[sitearchexp], q[so]]
#	CONST_CCCMD => q[CCCMD = $(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) \ 	$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \ 	$(XS_DEFINE_VERSION)]
#	CP => q[cp]
#	DEFINE => q[]
#	DIR => []
#	DIR_TARGET => { PACK001=HASH(...)=>{ $(INST_ARCHAUTODIR)=>q[3], $(INST_LIBDIR)=>q[1], $(INST_AUTODIR)=>q[1] } }
#	DISTNAME => q[Meschach]
#	DLBASE => q[$(BASEEXT)]
#	DLEXT => q[so]
#	DLSRC => q[dl_next.xs]
#	EXTRALIBS => q[-L/etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2 -lmes]
#	FIRST_MAKEFILE => q[Makefile]
#	FULLEXT => q[PDL/Meschach]
#	FULLPERL => q[/usr/bin/perl]
#	H => [q[Meschach.h], q[mespdl.h], q[p_funcs.h]]
#	HAS_LINK_CODE => q[1]
#	INC => q[-Imeschach-1.2 -I../../PDL/Core]
#	INSTALLARCHLIB => q[$(PREFIX)/lib/perl5/next/5.003]
#	INSTALLBIN => q[$(PREFIX)/bin]
#	INSTALLDIRS => q[site]
#	INSTALLMAN1DIR => q[$(PREFIX)/man/man1]
#	INSTALLMAN3DIR => q[$(PREFIX)/lib/perl5/man/man3]
#	INSTALLPRIVLIB => q[$(PREFIX)/lib/perl5]
#	INSTALLSCRIPT => q[$(PREFIX)/bin]
#	INSTALLSITEARCH => q[$(PREFIX)/lib/perl5/site_perl/next]
#	INSTALLSITELIB => q[$(PREFIX)/lib/perl5/site_perl]
#	INST_ARCHLIB => q[./blib/arch]
#	INST_BIN => q[./blib/bin]
#	INST_EXE => q[./blib/script]
#	INST_LIB => q[./blib/lib]
#	INST_MAN1DIR => q[./blib/man1]
#	INST_MAN3DIR => q[./blib/man3]
#	INST_SCRIPT => q[./blib/script]
#	LARGE => q[]
#	LD => q[ld]
#	LDDLFLAGS => q[-r -L/usr/local/lib]
#	LDFLAGS => q[-u libsys_s -L/usr/local/lib]
#	LDFROM => q[$(OBJECT)]
#	LDLOADLIBS => q[-L/etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2]
#	LD_RUN_PATH => q[/etienne/prog/perl/modules/PDL-1.04/PDL/Meschach-0.03/meschach-1.2]
#	LIBC => q[/lib/libsys_s.a]
#	LIBPERL_A => q[libperl.a]
#	LIBS => [q[-Lmeschach-1.2 -lmes], q[-lm]]
#	LIB_EXT => q[.a]
#	LINKTYPE => q[dynamic]
#	MAKEFILE => q[Makefile]
#	MAKE_APERL_FILE => q[Makefile.aperl]
#	MAN1EXT => q[1]
#	MAN1PODS => {  }
#	MAN3EXT => q[3]
#	MAN3PODS => {  }
#	MAP_TARGET => q[perl]
#	MV => q[mv]
#	NAME => q[PDL::Meschach]
#	NAME_SYM => q[PDL_Meschach]
#	NEEDS_LINKING => q[1]
#	NOECHO => q[@]
#	NOOP => q[sh -c true]
#	NORECURS => q[true]
#	OBJECT => q[mespdl$(OBJ_EXT) p_funcs$(OBJ_EXT) Meschach$(OBJ_EXT)]
#	OBJ_EXT => q[.o]
#	OPTIMIZE => q[-O]
#	O_FILES => [q[Meschach.o], q[mespdl.o], q[mespdl.old.o], q[p_funcs.o]]
#	PARENT_NAME => q[PDL::]
#	PERL => q[/usr/bin/perl]
#	PERLMAINCC => q[$(CC)]
#	PERLTYPE => undef
#	PERL_ARCHLIB => q[/usr/local/lib/perl5/next/5.003]
#	PERL_INC => q[/usr/local/lib/perl5/next/5.003/CORE]
#	PERL_LIB => q[/usr/local/lib/perl5]
#	PERL_SRC => undef
#	PL_FILES => {  }
#	PM => { Meschach.pm=>q[$(INST_LIBDIR)/Meschach.pm] }
#	PMLIBDIRS => []
#	PREFIX => q[/usr/local]
#	PREREQ_PM => {  }
#	RANLIB => q[sleep 5; /bin/ranlib]
#	RM_F => q[rm -f]
#	RM_RF => q[rm -rf]
#	SITEARCHEXP => q[/usr/local/lib/perl5/site_perl/next]
#	SITELIBEXP => q[/usr/local/lib/perl5/site_perl]
#	SKIPHASH => {  }
#	SO => q[so]
#	SPLIT => q[]
#	TOUCH => q[touch]
#	TYPEMAPS => [q[../../PDL/Core/typemap.pdl]]
#	UMASK_NULL => q[umask 0]
#	VERSION => q[0.03]
#	VERSION_FROM => q[Meschach.pm]
#	VERSION_SYM => q[0_03]
#	XS => { Meschach.xs=>q[Meschach.c] }
#	XSPROTOARG => q[]
#	XS_VERSION => q[0.03]
#	clean => { FILES=>q[mespdl.o p_funcs.o Meschach.o] }
#	dist => { COMPRESS=>q[gzip -9f] }

# --- MakeMaker postamble section:


# End.
