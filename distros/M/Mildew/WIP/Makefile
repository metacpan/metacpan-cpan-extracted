# This Makefile is for the Mildew extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.56 (Revision: 65600) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[the mildew Perl6 compiler]
#     AUTHOR => q[Pawel Murias <pawelmurias@gmail.com>, Daniel Ruoso <daniel@ruoso.com>]
#     BUILD_REQUIRES => {  }
#     CONFIGURE_REQUIRES => { ExtUtils::MakeMaker=>q[6.31] }
#     DISTNAME => q[Mildew]
#     EXE_FILES => [q[bin/mildew]]
#     LICENSE => q[artistic_2]
#     NAME => q[Mildew]
#     PREREQ_PM => { MooseX::Declare=>q[0.33], Regexp::Grammars=>q[1.002], Bread::Board=>q[0.13], Digest::MD4=>q[0], YAML::XS=>q[0], Data::Dumper::Concise=>q[1.200], STD=>q[0.05], Set::Object=>q[1.26], Graph::Easy=>q[0.69], Forest::Tree=>q[0.08], Moose=>q[1.03], File::Slurp=>q[0] }
#     VERSION => q[0.05]
#     test => { TESTS=>q[t/*.t] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/5.12.1/i686-linux/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS = -shared -O2 -L/usr/local/lib -fstack-protector
LDFLAGS =  -fstack-protector -L/usr/local/lib
LIBC = /lib/libc-2.10.2.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 2.6.32-3-686
RANLIB = :
SITELIBEXP = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/site_perl/5.12.1
SITEARCHEXP = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/site_perl/5.12.1/i686-linux
SO = so
VENDORARCHEXP = 
VENDORLIBEXP = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = Mildew
NAME_SYM = Mildew
VERSION = 0.05
VERSION_MACRO = VERSION
VERSION_SYM = 0_05
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.05
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /home/pawel/perl5/perlbrew/perls/perl-5.12.1
SITEPREFIX = /home/pawel/perl5/perlbrew/perls/perl-5.12.1
VENDORPREFIX = 
INSTALLPRIVLIB = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/5.12.1
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/site_perl/5.12.1
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = 
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/5.12.1/i686-linux
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/site_perl/5.12.1/i686-linux
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = 
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = 
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = 
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = 
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = 
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/5.12.1
PERL_ARCHLIB = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/5.12.1/i686-linux
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/5.12.1/i686-linux/CORE
PERL = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/bin/perl5.12.1
FULLPERL = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/bin/perl5.12.1
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/lib/5.12.1/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.56
MM_REVISION = 65600

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = Mildew
BASEEXT = Mildew
PARENT_NAME = 
DLBASE = $(BASEEXT)
VERSION_FROM = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = lib/Mildew/Backend/DumpAST.pm \
	lib/Mildew/Backend/Gtk.pm \
	lib/Mildew/SSA.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DFSEP)Config.pm $(PERL_INC)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/Mildew.pm \
	lib/Mildew/AST.pm \
	lib/Mildew/AST/Assign.pm \
	lib/Mildew/AST/Base.pm \
	lib/Mildew/AST/Block.pm \
	lib/Mildew/AST/Block/SSA.pm \
	lib/Mildew/AST/Block/Simplified.pm \
	lib/Mildew/AST/Branch.pm \
	lib/Mildew/AST/Call.pm \
	lib/Mildew/AST/Capture.pm \
	lib/Mildew/AST/Comment.pm \
	lib/Mildew/AST/Goto.pm \
	lib/Mildew/AST/Helpers.pm \
	lib/Mildew/AST/If.pm \
	lib/Mildew/AST/InferredTypeTest.pm \
	lib/Mildew/AST/IntegerConstant.pm \
	lib/Mildew/AST/Let.pm \
	lib/Mildew/AST/Loop.pm \
	lib/Mildew/AST/Pair.pm \
	lib/Mildew/AST/Phi.pm \
	lib/Mildew/AST/Reg.pm \
	lib/Mildew/AST/Seq.pm \
	lib/Mildew/AST/StringConstant.pm \
	lib/Mildew/AST/While.pm \
	lib/Mildew/Backend.pm \
	lib/Mildew/Backend/C.pm \
	lib/Mildew/Backend/C/M0ld.pm \
	lib/Mildew/Backend/C/So.pm \
	lib/Mildew/Backend/C/V6.pm \
	lib/Mildew/Backend/DumpAST.pm \
	lib/Mildew/Backend/Gtk.pm \
	lib/Mildew/Backend/OptC.pm \
	lib/Mildew/Backend/Perlesque.pm \
	lib/Mildew/Compiler.pm \
	lib/Mildew/Emit/Yeast.pm \
	lib/Mildew/Frontend/M0ld.pm \
	lib/Mildew/Frontend/STD.pm \
	lib/Mildew/Frontend/STD/Cached.pm \
	lib/Mildew/SSA.pm \
	lib/Mildew/Types.pm \
	lib/VAST.pm \
	lib/VAST/Chaining.pm \
	lib/VAST/Str.pm \
	lib/VAST/arglist.pm \
	lib/VAST/args.pm \
	lib/VAST/blockoid.pm \
	lib/VAST/circumfix__S_Cur_Ly.pm \
	lib/VAST/circumfix__S_Paren_Thesis.pm \
	lib/VAST/colonpair.pm \
	lib/VAST/comp_unit.pm \
	lib/VAST/dotty__S_Dot.pm \
	lib/VAST/dotty__S_DotStar.pm \
	lib/VAST/escape__S_Back.pm \
	lib/VAST/escape__S_Dollar.pm \
	lib/VAST/fatarrow.pm \
	lib/VAST/identifier.pm \
	lib/VAST/infix__S_AmpAmp.pm \
	lib/VAST/infix__S_ColonEqual.pm \
	lib/VAST/infix__S_Comma.pm \
	lib/VAST/infix__S_Equal.pm \
	lib/VAST/infix__S_VertVert.pm \
	lib/VAST/integer.pm \
	lib/VAST/longname.pm \
	lib/VAST/method_def.pm \
	lib/VAST/multi_declarator__S_multi.pm \
	lib/VAST/nibbler.pm \
	lib/VAST/package_declarator.pm \
	lib/VAST/package_declarator__S_module.pm \
	lib/VAST/parameter.pm \
	lib/VAST/postcircumfix__S_Bra_Ket.pm \
	lib/VAST/postcircumfix__S_Cur_Ly.pm \
	lib/VAST/postcircumfix__S_Lt_Gt.pm \
	lib/VAST/postcircumfix__S_Paren_Thesis.pm \
	lib/VAST/postfix__S_PlusPlus.pm \
	lib/VAST/prefix__S_PlusPlus.pm \
	lib/VAST/prefix__S_Vert.pm \
	lib/VAST/routine_def.pm \
	lib/VAST/scope_declarator__S_has.pm \
	lib/VAST/scope_declarator__S_my.pm \
	lib/VAST/scope_declarator__S_our.pm \
	lib/VAST/semiarglist.pm \
	lib/VAST/signature.pm \
	lib/VAST/statement.pm \
	lib/VAST/statement_control__S_CATCH.pm \
	lib/VAST/statement_control__S_CONTROL.pm \
	lib/VAST/statement_control__S_for.pm \
	lib/VAST/statement_control__S_if.pm \
	lib/VAST/statement_control__S_loop.pm \
	lib/VAST/statement_control__S_no.pm \
	lib/VAST/statement_control__S_unless.pm \
	lib/VAST/statement_control__S_until.pm \
	lib/VAST/statement_control__S_use.pm \
	lib/VAST/statement_control__S_while.pm \
	lib/VAST/statement_prefix__S_do.pm \
	lib/VAST/statementlist.pm \
	lib/VAST/sublongname.pm \
	lib/VAST/term__S_colonpair.pm \
	lib/VAST/term__S_identifier.pm \
	lib/VAST/term__S_name.pm \
	lib/VAST/term__S_self.pm \
	lib/VAST/variable.pm

PM_TO_BLIB = lib/VAST/postfix__S_PlusPlus.pm \
	blib/lib/VAST/postfix__S_PlusPlus.pm \
	lib/VAST/postcircumfix__S_Paren_Thesis.pm \
	blib/lib/VAST/postcircumfix__S_Paren_Thesis.pm \
	lib/VAST/arglist.pm \
	blib/lib/VAST/arglist.pm \
	lib/VAST/multi_declarator__S_multi.pm \
	blib/lib/VAST/multi_declarator__S_multi.pm \
	lib/VAST/infix__S_Comma.pm \
	blib/lib/VAST/infix__S_Comma.pm \
	lib/Mildew/Backend/C/So.pm \
	blib/lib/Mildew/Backend/C/So.pm \
	lib/Mildew/AST/Phi.pm \
	blib/lib/Mildew/AST/Phi.pm \
	lib/VAST/scope_declarator__S_my.pm \
	blib/lib/VAST/scope_declarator__S_my.pm \
	lib/Mildew/Frontend/STD.pm \
	blib/lib/Mildew/Frontend/STD.pm \
	lib/Mildew/AST/If.pm \
	blib/lib/Mildew/AST/If.pm \
	lib/VAST/postcircumfix__S_Bra_Ket.pm \
	blib/lib/VAST/postcircumfix__S_Bra_Ket.pm \
	lib/VAST/semiarglist.pm \
	blib/lib/VAST/semiarglist.pm \
	lib/Mildew/AST/Let.pm \
	blib/lib/Mildew/AST/Let.pm \
	lib/VAST/Str.pm \
	blib/lib/VAST/Str.pm \
	lib/Mildew/Backend/DumpAST.pm \
	blib/lib/Mildew/Backend/DumpAST.pm \
	lib/Mildew/Backend/Perlesque.pm \
	blib/lib/Mildew/Backend/Perlesque.pm \
	lib/VAST/parameter.pm \
	blib/lib/VAST/parameter.pm \
	lib/VAST/nibbler.pm \
	blib/lib/VAST/nibbler.pm \
	lib/Mildew/Emit/Yeast.pm \
	blib/lib/Mildew/Emit/Yeast.pm \
	lib/VAST/statement_control__S_loop.pm \
	blib/lib/VAST/statement_control__S_loop.pm \
	lib/VAST/statement.pm \
	blib/lib/VAST/statement.pm \
	lib/VAST/circumfix__S_Paren_Thesis.pm \
	blib/lib/VAST/circumfix__S_Paren_Thesis.pm \
	lib/VAST/sublongname.pm \
	blib/lib/VAST/sublongname.pm \
	lib/VAST/dotty__S_Dot.pm \
	blib/lib/VAST/dotty__S_Dot.pm \
	lib/VAST/infix__S_ColonEqual.pm \
	blib/lib/VAST/infix__S_ColonEqual.pm \
	lib/Mildew/AST/IntegerConstant.pm \
	blib/lib/Mildew/AST/IntegerConstant.pm \
	lib/VAST/term__S_identifier.pm \
	blib/lib/VAST/term__S_identifier.pm \
	lib/VAST/statement_control__S_CONTROL.pm \
	blib/lib/VAST/statement_control__S_CONTROL.pm \
	lib/Mildew/Backend/C/V6.pm \
	blib/lib/Mildew/Backend/C/V6.pm \
	lib/Mildew/AST.pm \
	blib/lib/Mildew/AST.pm \
	lib/Mildew/Backend.pm \
	blib/lib/Mildew/Backend.pm \
	lib/VAST/package_declarator__S_module.pm \
	blib/lib/VAST/package_declarator__S_module.pm \
	lib/VAST/term__S_self.pm \
	blib/lib/VAST/term__S_self.pm \
	lib/VAST/blockoid.pm \
	blib/lib/VAST/blockoid.pm \
	lib/VAST/package_declarator.pm \
	blib/lib/VAST/package_declarator.pm \
	lib/Mildew/Types.pm \
	blib/lib/Mildew/Types.pm \
	lib/VAST/scope_declarator__S_our.pm \
	blib/lib/VAST/scope_declarator__S_our.pm \
	lib/Mildew/Frontend/M0ld.pm \
	blib/lib/Mildew/Frontend/M0ld.pm \
	lib/VAST/statement_prefix__S_do.pm \
	blib/lib/VAST/statement_prefix__S_do.pm \
	lib/VAST/statement_control__S_no.pm \
	blib/lib/VAST/statement_control__S_no.pm \
	lib/Mildew/AST/Loop.pm \
	blib/lib/Mildew/AST/Loop.pm \
	lib/Mildew/Backend/C.pm \
	blib/lib/Mildew/Backend/C.pm \
	lib/VAST/statement_control__S_for.pm \
	blib/lib/VAST/statement_control__S_for.pm \
	lib/VAST/infix__S_Equal.pm \
	blib/lib/VAST/infix__S_Equal.pm \
	lib/Mildew/Backend/Gtk.pm \
	blib/lib/Mildew/Backend/Gtk.pm \
	lib/VAST/escape__S_Dollar.pm \
	blib/lib/VAST/escape__S_Dollar.pm \
	lib/Mildew/SSA.pm \
	blib/lib/Mildew/SSA.pm \
	lib/VAST/term__S_name.pm \
	blib/lib/VAST/term__S_name.pm \
	lib/VAST/Chaining.pm \
	blib/lib/VAST/Chaining.pm \
	lib/Mildew/AST/Seq.pm \
	blib/lib/Mildew/AST/Seq.pm \
	lib/VAST/fatarrow.pm \
	blib/lib/VAST/fatarrow.pm \
	lib/Mildew/AST/While.pm \
	blib/lib/Mildew/AST/While.pm \
	lib/VAST/statement_control__S_until.pm \
	blib/lib/VAST/statement_control__S_until.pm \
	lib/VAST/prefix__S_Vert.pm \
	blib/lib/VAST/prefix__S_Vert.pm \
	lib/Mildew/AST/Capture.pm \
	blib/lib/Mildew/AST/Capture.pm \
	lib/Mildew/AST/Reg.pm \
	blib/lib/Mildew/AST/Reg.pm \
	lib/VAST/statementlist.pm \
	blib/lib/VAST/statementlist.pm \
	lib/VAST/integer.pm \
	blib/lib/VAST/integer.pm \
	lib/VAST/prefix__S_PlusPlus.pm \
	blib/lib/VAST/prefix__S_PlusPlus.pm \
	lib/VAST/variable.pm \
	blib/lib/VAST/variable.pm \
	lib/VAST/term__S_colonpair.pm \
	blib/lib/VAST/term__S_colonpair.pm \
	lib/VAST/args.pm \
	blib/lib/VAST/args.pm \
	lib/Mildew/AST/Block.pm \
	blib/lib/Mildew/AST/Block.pm \
	lib/VAST/postcircumfix__S_Cur_Ly.pm \
	blib/lib/VAST/postcircumfix__S_Cur_Ly.pm \
	lib/VAST/statement_control__S_if.pm \
	blib/lib/VAST/statement_control__S_if.pm \
	lib/Mildew/AST/StringConstant.pm \
	blib/lib/Mildew/AST/StringConstant.pm \
	lib/Mildew/AST/Branch.pm \
	blib/lib/Mildew/AST/Branch.pm \
	lib/Mildew/AST/Goto.pm \
	blib/lib/Mildew/AST/Goto.pm \
	lib/Mildew/AST/Comment.pm \
	blib/lib/Mildew/AST/Comment.pm \
	lib/Mildew/Backend/OptC.pm \
	blib/lib/Mildew/Backend/OptC.pm \
	lib/VAST/longname.pm \
	blib/lib/VAST/longname.pm \
	lib/VAST/postcircumfix__S_Lt_Gt.pm \
	blib/lib/VAST/postcircumfix__S_Lt_Gt.pm \
	lib/VAST/colonpair.pm \
	blib/lib/VAST/colonpair.pm \
	lib/VAST/method_def.pm \
	blib/lib/VAST/method_def.pm \
	lib/VAST/statement_control__S_use.pm \
	blib/lib/VAST/statement_control__S_use.pm \
	lib/VAST/statement_control__S_while.pm \
	blib/lib/VAST/statement_control__S_while.pm \
	lib/Mildew/Backend/C/M0ld.pm \
	blib/lib/Mildew/Backend/C/M0ld.pm \
	lib/VAST/dotty__S_DotStar.pm \
	blib/lib/VAST/dotty__S_DotStar.pm \
	lib/Mildew/Frontend/STD/Cached.pm \
	blib/lib/Mildew/Frontend/STD/Cached.pm \
	lib/VAST/comp_unit.pm \
	blib/lib/VAST/comp_unit.pm \
	lib/Mildew/AST/Block/SSA.pm \
	blib/lib/Mildew/AST/Block/SSA.pm \
	lib/Mildew/AST/InferredTypeTest.pm \
	blib/lib/Mildew/AST/InferredTypeTest.pm \
	lib/Mildew/AST/Base.pm \
	blib/lib/Mildew/AST/Base.pm \
	lib/Mildew/AST/Helpers.pm \
	blib/lib/Mildew/AST/Helpers.pm \
	lib/VAST.pm \
	blib/lib/VAST.pm \
	lib/VAST/escape__S_Back.pm \
	blib/lib/VAST/escape__S_Back.pm \
	lib/VAST/statement_control__S_CATCH.pm \
	blib/lib/VAST/statement_control__S_CATCH.pm \
	lib/VAST/signature.pm \
	blib/lib/VAST/signature.pm \
	lib/Mildew/AST/Call.pm \
	blib/lib/Mildew/AST/Call.pm \
	lib/Mildew/Compiler.pm \
	blib/lib/Mildew/Compiler.pm \
	lib/VAST/infix__S_AmpAmp.pm \
	blib/lib/VAST/infix__S_AmpAmp.pm \
	lib/VAST/statement_control__S_unless.pm \
	blib/lib/VAST/statement_control__S_unless.pm \
	lib/Mildew/AST/Assign.pm \
	blib/lib/Mildew/AST/Assign.pm \
	lib/VAST/scope_declarator__S_has.pm \
	blib/lib/VAST/scope_declarator__S_has.pm \
	lib/VAST/routine_def.pm \
	blib/lib/VAST/routine_def.pm \
	lib/VAST/identifier.pm \
	blib/lib/VAST/identifier.pm \
	lib/Mildew/AST/Block/Simplified.pm \
	blib/lib/Mildew/AST/Block/Simplified.pm \
	lib/VAST/circumfix__S_Cur_Ly.pm \
	blib/lib/VAST/circumfix__S_Cur_Ly.pm \
	lib/VAST/infix__S_VertVert.pm \
	blib/lib/VAST/infix__S_VertVert.pm \
	lib/Mildew/AST/Pair.pm \
	blib/lib/Mildew/AST/Pair.pm \
	lib/Mildew.pm \
	blib/lib/Mildew.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 6.56
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = Mildew
DISTVNAME = Mildew-0.05


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	lib/Mildew/Backend/Gtk.pm \
	lib/Mildew/Backend/DumpAST.pm \
	lib/Mildew/SSA.pm
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW) \
	  lib/Mildew/Backend/Gtk.pm $(INST_MAN3DIR)/Mildew::Backend::Gtk.$(MAN3EXT) \
	  lib/Mildew/Backend/DumpAST.pm $(INST_MAN3DIR)/Mildew::Backend::DumpAST.$(MAN3EXT) \
	  lib/Mildew/SSA.pm $(INST_MAN3DIR)/Mildew::SSA.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = bin/mildew

pure_all :: $(INST_SCRIPT)/mildew
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/mildew 

$(INST_SCRIPT)/mildew : bin/mildew $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/mildew
	$(CP) bin/mildew $(INST_SCRIPT)/mildew
	$(FIXIN) $(INST_SCRIPT)/mildew
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/mildew



# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  *$(LIB_EXT) core \
	  core.[0-9] $(INST_ARCHAUTODIR)/extralibs.all \
	  core.[0-9][0-9] $(BASEEXT).bso \
	  pm_to_blib.ts core.[0-9][0-9][0-9][0-9] \
	  $(BASEEXT).x $(BOOTSTRAP) \
	  perl$(EXE_EXT) tmon.out \
	  *$(OBJ_EXT) pm_to_blib \
	  $(INST_ARCHAUTODIR)/extralibs.ld blibdirs.ts \
	  core.[0-9][0-9][0-9][0-9][0-9] *perl.core \
	  core.*perl.*.? $(MAKE_APERL_FILE) \
	  perl $(BASEEXT).def \
	  core.[0-9][0-9][0-9] mon.out \
	  lib$(BASEEXT).def perlmain.c \
	  perl.exe so_locations \
	  $(BASEEXT).exp 
	- $(RM_RF) \
	  blib 
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge ::  clean realclean_subdirs
	- $(RM_F) \
	  $(MAKEFILE_OLD) $(FIRST_MAKEFILE) 
	- $(RM_RF) \
	  $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '--- #YAML:1.0' > META_new.yml
	$(NOECHO) $(ECHO) 'name:               Mildew' >> META_new.yml
	$(NOECHO) $(ECHO) 'version:            0.05' >> META_new.yml
	$(NOECHO) $(ECHO) 'abstract:           the mildew Perl6 compiler' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - Pawel Murias <pawelmurias@gmail.com>, Daniel Ruoso <daniel@ruoso.com>' >> META_new.yml
	$(NOECHO) $(ECHO) 'license:            artistic_2' >> META_new.yml
	$(NOECHO) $(ECHO) 'distribution_type:  module' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '    ExtUtils::MakeMaker:  6.31' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:  {}' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '    Bread::Board:         0.13' >> META_new.yml
	$(NOECHO) $(ECHO) '    Data::Dumper::Concise:  1.200' >> META_new.yml
	$(NOECHO) $(ECHO) '    Digest::MD4:          0' >> META_new.yml
	$(NOECHO) $(ECHO) '    File::Slurp:          0' >> META_new.yml
	$(NOECHO) $(ECHO) '    Forest::Tree:         0.08' >> META_new.yml
	$(NOECHO) $(ECHO) '    Graph::Easy:          0.69' >> META_new.yml
	$(NOECHO) $(ECHO) '    Moose:                1.03' >> META_new.yml
	$(NOECHO) $(ECHO) '    MooseX::Declare:      0.33' >> META_new.yml
	$(NOECHO) $(ECHO) '    Regexp::Grammars:     1.002' >> META_new.yml
	$(NOECHO) $(ECHO) '    Set::Object:          1.26' >> META_new.yml
	$(NOECHO) $(ECHO) '    STD:                  0.05' >> META_new.yml
	$(NOECHO) $(ECHO) '    YAML::XS:             0' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '    directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '        - t' >> META_new.yml
	$(NOECHO) $(ECHO) '        - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by:       ExtUtils::MakeMaker version 6.56' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '    url:      http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '    version:  1.4' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old 



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{META.yml} => q{Module meta-data (added by MakeMaker)}}) } ' \
	  -e '    or print "Could not add META.yml to MANIFEST: $${'\''@'\''}\n"' --



# --- MakeMaker distsignature section:
distsignature : create_distdir
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) } ' \
	  -e '    or print "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSITESCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLVENDORSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /home/pawel/perl5/perlbrew/perls/perl-5.12.1/bin/perl5.12.1

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE) subdirs-test

subdirs-test ::
	$(NOECHO) $(NOOP)


test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="0.05">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>the mildew Perl6 compiler</ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Pawel Murias &lt;pawelmurias@gmail.com&gt;, Daniel Ruoso &lt;daniel@ruoso.com&gt;</AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Bread::Board" VERSION="0.13" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Data::Dumper::Concise" VERSION="1.2" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Digest::MD4" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Slurp" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Forest::Tree" VERSION="0.08" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Graph::Easy" VERSION="0.69" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Moose::" VERSION="1.03" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="MooseX::Declare" VERSION="0.33" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Regexp::Grammars" VERSION="1.002" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="STD::" VERSION="0.05" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Set::Object" VERSION="1.26" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="YAML::XS" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="i686-linux-5.12" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/VAST/postfix__S_PlusPlus.pm blib/lib/VAST/postfix__S_PlusPlus.pm \
	  lib/VAST/postcircumfix__S_Paren_Thesis.pm blib/lib/VAST/postcircumfix__S_Paren_Thesis.pm \
	  lib/VAST/arglist.pm blib/lib/VAST/arglist.pm \
	  lib/VAST/multi_declarator__S_multi.pm blib/lib/VAST/multi_declarator__S_multi.pm \
	  lib/VAST/infix__S_Comma.pm blib/lib/VAST/infix__S_Comma.pm \
	  lib/Mildew/Backend/C/So.pm blib/lib/Mildew/Backend/C/So.pm \
	  lib/Mildew/AST/Phi.pm blib/lib/Mildew/AST/Phi.pm \
	  lib/VAST/scope_declarator__S_my.pm blib/lib/VAST/scope_declarator__S_my.pm \
	  lib/Mildew/Frontend/STD.pm blib/lib/Mildew/Frontend/STD.pm \
	  lib/Mildew/AST/If.pm blib/lib/Mildew/AST/If.pm \
	  lib/VAST/postcircumfix__S_Bra_Ket.pm blib/lib/VAST/postcircumfix__S_Bra_Ket.pm \
	  lib/VAST/semiarglist.pm blib/lib/VAST/semiarglist.pm \
	  lib/Mildew/AST/Let.pm blib/lib/Mildew/AST/Let.pm \
	  lib/VAST/Str.pm blib/lib/VAST/Str.pm \
	  lib/Mildew/Backend/DumpAST.pm blib/lib/Mildew/Backend/DumpAST.pm \
	  lib/Mildew/Backend/Perlesque.pm blib/lib/Mildew/Backend/Perlesque.pm \
	  lib/VAST/parameter.pm blib/lib/VAST/parameter.pm \
	  lib/VAST/nibbler.pm blib/lib/VAST/nibbler.pm \
	  lib/Mildew/Emit/Yeast.pm blib/lib/Mildew/Emit/Yeast.pm \
	  lib/VAST/statement_control__S_loop.pm blib/lib/VAST/statement_control__S_loop.pm \
	  lib/VAST/statement.pm blib/lib/VAST/statement.pm \
	  lib/VAST/circumfix__S_Paren_Thesis.pm blib/lib/VAST/circumfix__S_Paren_Thesis.pm \
	  lib/VAST/sublongname.pm blib/lib/VAST/sublongname.pm \
	  lib/VAST/dotty__S_Dot.pm blib/lib/VAST/dotty__S_Dot.pm \
	  lib/VAST/infix__S_ColonEqual.pm blib/lib/VAST/infix__S_ColonEqual.pm \
	  lib/Mildew/AST/IntegerConstant.pm blib/lib/Mildew/AST/IntegerConstant.pm \
	  lib/VAST/term__S_identifier.pm blib/lib/VAST/term__S_identifier.pm \
	  lib/VAST/statement_control__S_CONTROL.pm blib/lib/VAST/statement_control__S_CONTROL.pm \
	  lib/Mildew/Backend/C/V6.pm blib/lib/Mildew/Backend/C/V6.pm \
	  lib/Mildew/AST.pm blib/lib/Mildew/AST.pm \
	  lib/Mildew/Backend.pm blib/lib/Mildew/Backend.pm \
	  lib/VAST/package_declarator__S_module.pm blib/lib/VAST/package_declarator__S_module.pm \
	  lib/VAST/term__S_self.pm blib/lib/VAST/term__S_self.pm \
	  lib/VAST/blockoid.pm blib/lib/VAST/blockoid.pm \
	  lib/VAST/package_declarator.pm blib/lib/VAST/package_declarator.pm \
	  lib/Mildew/Types.pm blib/lib/Mildew/Types.pm \
	  lib/VAST/scope_declarator__S_our.pm blib/lib/VAST/scope_declarator__S_our.pm \
	  lib/Mildew/Frontend/M0ld.pm blib/lib/Mildew/Frontend/M0ld.pm \
	  lib/VAST/statement_prefix__S_do.pm blib/lib/VAST/statement_prefix__S_do.pm \
	  lib/VAST/statement_control__S_no.pm blib/lib/VAST/statement_control__S_no.pm \
	  lib/Mildew/AST/Loop.pm blib/lib/Mildew/AST/Loop.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/Mildew/Backend/C.pm blib/lib/Mildew/Backend/C.pm \
	  lib/VAST/statement_control__S_for.pm blib/lib/VAST/statement_control__S_for.pm \
	  lib/VAST/infix__S_Equal.pm blib/lib/VAST/infix__S_Equal.pm \
	  lib/Mildew/Backend/Gtk.pm blib/lib/Mildew/Backend/Gtk.pm \
	  lib/VAST/escape__S_Dollar.pm blib/lib/VAST/escape__S_Dollar.pm \
	  lib/Mildew/SSA.pm blib/lib/Mildew/SSA.pm \
	  lib/VAST/term__S_name.pm blib/lib/VAST/term__S_name.pm \
	  lib/VAST/Chaining.pm blib/lib/VAST/Chaining.pm \
	  lib/Mildew/AST/Seq.pm blib/lib/Mildew/AST/Seq.pm \
	  lib/VAST/fatarrow.pm blib/lib/VAST/fatarrow.pm \
	  lib/Mildew/AST/While.pm blib/lib/Mildew/AST/While.pm \
	  lib/VAST/statement_control__S_until.pm blib/lib/VAST/statement_control__S_until.pm \
	  lib/VAST/prefix__S_Vert.pm blib/lib/VAST/prefix__S_Vert.pm \
	  lib/Mildew/AST/Capture.pm blib/lib/Mildew/AST/Capture.pm \
	  lib/Mildew/AST/Reg.pm blib/lib/Mildew/AST/Reg.pm \
	  lib/VAST/statementlist.pm blib/lib/VAST/statementlist.pm \
	  lib/VAST/integer.pm blib/lib/VAST/integer.pm \
	  lib/VAST/prefix__S_PlusPlus.pm blib/lib/VAST/prefix__S_PlusPlus.pm \
	  lib/VAST/variable.pm blib/lib/VAST/variable.pm \
	  lib/VAST/term__S_colonpair.pm blib/lib/VAST/term__S_colonpair.pm \
	  lib/VAST/args.pm blib/lib/VAST/args.pm \
	  lib/Mildew/AST/Block.pm blib/lib/Mildew/AST/Block.pm \
	  lib/VAST/postcircumfix__S_Cur_Ly.pm blib/lib/VAST/postcircumfix__S_Cur_Ly.pm \
	  lib/VAST/statement_control__S_if.pm blib/lib/VAST/statement_control__S_if.pm \
	  lib/Mildew/AST/StringConstant.pm blib/lib/Mildew/AST/StringConstant.pm \
	  lib/Mildew/AST/Branch.pm blib/lib/Mildew/AST/Branch.pm \
	  lib/Mildew/AST/Goto.pm blib/lib/Mildew/AST/Goto.pm \
	  lib/Mildew/AST/Comment.pm blib/lib/Mildew/AST/Comment.pm \
	  lib/Mildew/Backend/OptC.pm blib/lib/Mildew/Backend/OptC.pm \
	  lib/VAST/longname.pm blib/lib/VAST/longname.pm \
	  lib/VAST/postcircumfix__S_Lt_Gt.pm blib/lib/VAST/postcircumfix__S_Lt_Gt.pm \
	  lib/VAST/colonpair.pm blib/lib/VAST/colonpair.pm \
	  lib/VAST/method_def.pm blib/lib/VAST/method_def.pm \
	  lib/VAST/statement_control__S_use.pm blib/lib/VAST/statement_control__S_use.pm \
	  lib/VAST/statement_control__S_while.pm blib/lib/VAST/statement_control__S_while.pm \
	  lib/Mildew/Backend/C/M0ld.pm blib/lib/Mildew/Backend/C/M0ld.pm \
	  lib/VAST/dotty__S_DotStar.pm blib/lib/VAST/dotty__S_DotStar.pm \
	  lib/Mildew/Frontend/STD/Cached.pm blib/lib/Mildew/Frontend/STD/Cached.pm \
	  lib/VAST/comp_unit.pm blib/lib/VAST/comp_unit.pm \
	  lib/Mildew/AST/Block/SSA.pm blib/lib/Mildew/AST/Block/SSA.pm \
	  lib/Mildew/AST/InferredTypeTest.pm blib/lib/Mildew/AST/InferredTypeTest.pm \
	  lib/Mildew/AST/Base.pm blib/lib/Mildew/AST/Base.pm \
	  lib/Mildew/AST/Helpers.pm blib/lib/Mildew/AST/Helpers.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/VAST.pm blib/lib/VAST.pm \
	  lib/VAST/escape__S_Back.pm blib/lib/VAST/escape__S_Back.pm \
	  lib/VAST/statement_control__S_CATCH.pm blib/lib/VAST/statement_control__S_CATCH.pm \
	  lib/VAST/signature.pm blib/lib/VAST/signature.pm \
	  lib/Mildew/AST/Call.pm blib/lib/Mildew/AST/Call.pm \
	  lib/Mildew/Compiler.pm blib/lib/Mildew/Compiler.pm \
	  lib/VAST/infix__S_AmpAmp.pm blib/lib/VAST/infix__S_AmpAmp.pm \
	  lib/VAST/statement_control__S_unless.pm blib/lib/VAST/statement_control__S_unless.pm \
	  lib/Mildew/AST/Assign.pm blib/lib/Mildew/AST/Assign.pm \
	  lib/VAST/scope_declarator__S_has.pm blib/lib/VAST/scope_declarator__S_has.pm \
	  lib/VAST/routine_def.pm blib/lib/VAST/routine_def.pm \
	  lib/VAST/identifier.pm blib/lib/VAST/identifier.pm \
	  lib/Mildew/AST/Block/Simplified.pm blib/lib/Mildew/AST/Block/Simplified.pm \
	  lib/VAST/circumfix__S_Cur_Ly.pm blib/lib/VAST/circumfix__S_Cur_Ly.pm \
	  lib/VAST/infix__S_VertVert.pm blib/lib/VAST/infix__S_VertVert.pm \
	  lib/Mildew/AST/Pair.pm blib/lib/Mildew/AST/Pair.pm \
	  lib/Mildew.pm blib/lib/Mildew.pm 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
