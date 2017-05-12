package Devel::PatchPerl::Plugin::Cygwin;

use strict;
use warnings;

# ABSTRACT: Devel::PatchPerl plugin for Cygwin
our $VERSION = 'v0.0.1'; # VERSION

use File::pushd qw[pushd];
use File::Spec;

my @patch = (
	{
		perl => [
			qr/^5\.10\.1$/,
			qr/^5\.16\.[0-3]$/,
			qr/^5\.18\.[0-2]$/,
			qr/^5\.19\.[0-8]$/,
		],
		subs => [ [ \&_patch_cygwin_c_stdio ] ],
	},
	{
		perl => [ qr/^5\.10\.1$/ ],
		subs => [ [ \&_patch_cygwin17 ] ],
	},
	{
		perl => [ qr/^5\.8\.[0-8]$/ ],
		subs => [ [ \&_patch_cygwin_ld2 ] ],
	},
);

sub patchperl
{
	return unless $^O eq 'cygwin';

# TODO: Warn environment variables including parens.

	require Devel::PatchPerl;
# Devel::PatchPerl::_patch(),_is() are NOT a public interface, so the existence SHOULD NOT be relied
	if(! defined *Devel::PatchPerl::_patch{CODE} || ! defined *Devel::PatchPerl::_is{CODE}) {
		die 'Devel::PatchPerl::_patch() or Devel::PatchPerl::_is() not found, please contact with the author of '.__PACKAGE__;
	}

	shift if eval { $_[0]->isa(__PACKAGE__) };
	my (%args) = @_;
# Copy from Devel::PatchPerl::patch_source()
	my $source = File::Spec->rel2abs($args{source});
	{
		my $dir = pushd( $source );
		for my $p ( grep { Devel::PatchPerl::_is( $_->{perl}, $args{version} ) } @patch ) {
			for my $s (@{$p->{subs}}) {
				my($sub, @args) = @$s;
				push @args, $args{version} unless scalar @args;
				$sub->(@args);
			}
		}
	}
}

sub _patch_cygwin_c_stdio
{
	Devel::PatchPerl::_patch(<<'END');
--- cygwin/cygwin.c.orig        2014-01-13 09:20:07.000000000 +0900
+++ cygwin/cygwin.c     2014-05-02 19:16:25.950179100 +0900
@@ -2,6 +2,7 @@
  * Cygwin extras
  */

+#define PERLIO_NOT_STDIO 0
 #include "EXTERN.h"
 #include "perl.h"
 #undef USE_DYNAMIC_LOADING
END
}

sub _patch_cygwin17
{
	Devel::PatchPerl::_patch(<<'END');
--- cygwin/cygwin.c.orig	2009-05-04 01:54:56.000000000 +0900
+++ cygwin/cygwin.c	2014-05-03 19:39:53.093468100 +0900
@@ -10,9 +10,13 @@
 #include <unistd.h>
 #include <process.h>
 #include <sys/cygwin.h>
+#include <cygwin/version.h>
 #include <mntent.h>
 #include <alloca.h>
 #include <dlfcn.h>
+#if (CYGWIN_VERSION_API_MINOR >= 181)
+#include <wchar.h>
+#endif
 
 /*
  * pp_system() implemented via spawn()
@@ -140,6 +144,44 @@
     return do_spawnvp(PL_Argv[0],(const char * const *)PL_Argv);
 }
 
+#if (CYGWIN_VERSION_API_MINOR >= 181)
+char*
+wide_to_utf8(const wchar_t *wbuf)
+{
+    char *buf;
+    int wlen = 0;
+    char *oldlocale = setlocale(LC_CTYPE, NULL);
+    setlocale(LC_CTYPE, "utf-8");
+
+    /* uvuni_to_utf8(buf, chr) or Encoding::_bytes_to_utf8(sv, "UCS-2BE"); */
+    wlen = wcsrtombs(NULL, (const wchar_t **)&wbuf, wlen, NULL);
+    buf = (char *) safemalloc(wlen+1);
+    wcsrtombs(buf, (const wchar_t **)&wbuf, wlen, NULL);
+
+    if (oldlocale) setlocale(LC_CTYPE, oldlocale);
+    else setlocale(LC_CTYPE, "C");
+    return buf;
+}
+
+wchar_t*
+utf8_to_wide(const char *buf)
+{
+    wchar_t *wbuf;
+    mbstate_t mbs;
+    char *oldlocale = setlocale(LC_CTYPE, NULL);
+    int wlen = sizeof(wchar_t)*strlen(buf);
+
+    setlocale(LC_CTYPE, "utf-8");
+    wbuf = (wchar_t *) safemalloc(wlen);
+    /* utf8_to_uvuni_buf(pathname, pathname + wlen, wpath) or Encoding::_utf8_to_bytes(sv, "UCS-2BE"); */
+    wlen = mbsrtowcs(wbuf, (const char**)&buf, wlen, &mbs);
+
+    if (oldlocale) setlocale(LC_CTYPE, oldlocale);
+    else setlocale(LC_CTYPE, "C");
+    return wbuf;
+}
+#endif /* cygwin 1.7 */
+
 /* see also Cwd.pm */
 XS(Cygwin_cwd)
 {
@@ -191,7 +233,12 @@
 
     pid = (pid_t)SvIV(ST(0));
 
-    if ((RETVAL = cygwin32_winpid_to_pid(pid)) > 0) {
+#if (CYGWIN_VERSION_API_MINOR >= 181)
+    RETVAL = cygwin_winpid_to_pid(pid);
+#else
+    RETVAL = cygwin32_winpid_to_pid(pid);
+#endif
+    if (RETVAL > 0) {
         XSprePUSH; PUSHi((IV)RETVAL);
         XSRETURN(1);
     }
@@ -204,29 +251,85 @@
     int absolute_flag = 0;
     STRLEN len;
     int err;
-    char *pathname, *buf;
+    char *src_path;
+    char *posix_path;
+    int isutf8 = 0;
 
     if (items < 1 || items > 2)
         Perl_croak(aTHX_ "Usage: Cygwin::win_to_posix_path(pathname, [absolute])");
 
-    pathname = SvPV(ST(0), len);
+    src_path = SvPV(ST(0), len);
     if (items == 2)
 	absolute_flag = SvTRUE(ST(1));
 
     if (!len)
 	Perl_croak(aTHX_ "can't convert empty path");
-    buf = (char *) safemalloc (len + 260 + 1001);
+    isutf8 = SvUTF8(ST(0));
 
+#if (CYGWIN_VERSION_API_MINOR >= 181)
+    /* Check utf8 flag and use wide api then.
+       Size calculation: On overflow let cygwin_conv_path calculate the final size.
+     */
+    if (isutf8) {
+	int what = absolute_flag ? CCP_WIN_W_TO_POSIX : CCP_WIN_W_TO_POSIX | CCP_RELATIVE;
+	int wlen = sizeof(wchar_t)*(len + 260 + 1001);
+	wchar_t *wpath = (wchar_t *) safemalloc(sizeof(wchar_t)*len);
+	wchar_t *wbuf = (wchar_t *) safemalloc(wlen);
+	if (!IN_BYTES) {
+	    mbstate_t mbs;
+            char *oldlocale = setlocale(LC_CTYPE, NULL);
+            setlocale(LC_CTYPE, "utf-8");
+	    /* utf8_to_uvuni_buf(src_path, src_path + wlen, wpath) or Encoding::_utf8_to_bytes(sv, "UCS-2BE"); */
+	    wlen = mbsrtowcs(wpath, (const char**)&src_path, wlen, &mbs);
+	    if (wlen > 0)
+		err = cygwin_conv_path(what, wpath, wbuf, wlen);
+            if (oldlocale) setlocale(LC_CTYPE, oldlocale);
+            else setlocale(LC_CTYPE, "C");
+	} else { /* use bytes; assume already ucs-2 encoded bytestream */
+	    err = cygwin_conv_path(what, src_path, wbuf, wlen);
+	}
+	if (err == ENOSPC) { /* our space assumption was wrong, not enough space */
+	    int newlen = cygwin_conv_path(what, wpath, wbuf, 0);
+	    wbuf = (wchar_t *) realloc(&wbuf, newlen);
+	    err = cygwin_conv_path(what, wpath, wbuf, newlen);
+	    wlen = newlen;
+	}
+	/* utf16_to_utf8(*p, *d, bytlen, *newlen) */
+	posix_path = (char *) safemalloc(wlen*3);
+	Perl_utf16_to_utf8(aTHX_ (U8*)&wpath, (U8*)posix_path, (I32)wlen*2, (I32*)&len);
+	/*
+	wlen = wcsrtombs(NULL, (const wchar_t **)&wbuf, wlen, NULL);
+	posix_path = (char *) safemalloc(wlen+1);
+	wcsrtombs(posix_path, (const wchar_t **)&wbuf, wlen, NULL);
+	*/
+    } else {
+	int what = absolute_flag ? CCP_WIN_A_TO_POSIX : CCP_WIN_A_TO_POSIX | CCP_RELATIVE;
+	posix_path = (char *) safemalloc (len + 260 + 1001);
+	err = cygwin_conv_path(what, src_path, posix_path, len + 260 + 1001);
+	if (err == ENOSPC) { /* our space assumption was wrong, not enough space */
+	    int newlen = cygwin_conv_path(what, src_path, posix_path, 0);
+	    posix_path = (char *) realloc(&posix_path, newlen);
+	    err = cygwin_conv_path(what, src_path, posix_path, newlen);
+	}
+    }
+#else
+    posix_path = (char *) safemalloc (len + 260 + 1001);
     if (absolute_flag)
-	err = cygwin_conv_to_full_posix_path(pathname, buf);
+	err = cygwin_conv_to_full_posix_path(src_path, posix_path);
     else
-	err = cygwin_conv_to_posix_path(pathname, buf);
+	err = cygwin_conv_to_posix_path(src_path, posix_path);
+#endif
     if (!err) {
-	ST(0) = sv_2mortal(newSVpv(buf, 0));
-	safefree(buf);
-       XSRETURN(1);
+	EXTEND(SP, 1);
+	ST(0) = sv_2mortal(newSVpv(posix_path, 0));
+	if (isutf8) { /* src was utf-8, so result should also */
+	    /* TODO: convert ANSI (local windows encoding) to utf-8 on cygwin-1.5 */
+	    SvUTF8_on(ST(0));
+	}
+	safefree(posix_path);
+        XSRETURN(1);
     } else {
-	safefree(buf);
+	safefree(posix_path);
 	XSRETURN_UNDEF;
     }
 }
@@ -237,29 +340,80 @@
     int absolute_flag = 0;
     STRLEN len;
     int err;
-    char *pathname, *buf;
+    char *src_path, *win_path;
+    int isutf8 = 0;
 
     if (items < 1 || items > 2)
         Perl_croak(aTHX_ "Usage: Cygwin::posix_to_win_path(pathname, [absolute])");
 
-    pathname = SvPV(ST(0), len);
+    src_path = SvPVx(ST(0), len);
     if (items == 2)
 	absolute_flag = SvTRUE(ST(1));
 
     if (!len)
 	Perl_croak(aTHX_ "can't convert empty path");
-    buf = (char *) safemalloc(len + 260 + 1001);
-
+    isutf8 = SvUTF8(ST(0));
+#if (CYGWIN_VERSION_API_MINOR >= 181)
+    /* Check utf8 flag and use wide api then.
+       Size calculation: On overflow let cygwin_conv_path calculate the final size.
+     */
+    if (isutf8) {
+	int what = absolute_flag ? CCP_POSIX_TO_WIN_W : CCP_POSIX_TO_WIN_W | CCP_RELATIVE;
+	int wlen = sizeof(wchar_t)*(len + 260 + 1001);
+	wchar_t *wpath = (wchar_t *) safemalloc(sizeof(wchar_t)*len);
+	wchar_t *wbuf = (wchar_t *) safemalloc(wlen);
+	char *oldlocale = setlocale(LC_CTYPE, NULL);
+	setlocale(LC_CTYPE, "utf-8");
+	if (!IN_BYTES) {
+	    mbstate_t mbs;
+	    /* utf8_to_uvuni_buf(src_path, src_path + wlen, wpath) or Encoding::_utf8_to_bytes(sv, "UCS-2BE"); */
+	    wlen = mbsrtowcs(wpath, (const char**)&src_path, wlen, &mbs);
+	    if (wlen > 0)
+		err = cygwin_conv_path(what, wpath, wbuf, wlen);
+	} else { /* use bytes; assume already ucs-2 encoded bytestream */
+	    err = cygwin_conv_path(what, src_path, wbuf, wlen);
+	}
+	if (err == ENOSPC) { /* our space assumption was wrong, not enough space */
+	    int newlen = cygwin_conv_path(what, wpath, wbuf, 0);
+	    wbuf = (wchar_t *) realloc(&wbuf, newlen);
+	    err = cygwin_conv_path(what, wpath, wbuf, newlen);
+	    wlen = newlen;
+	}
+	/* also see utf8.c: Perl_utf16_to_utf8() or Encoding::_bytes_to_utf8(sv, "UCS-2BE"); */
+	wlen = wcsrtombs(NULL, (const wchar_t **)&wbuf, wlen, NULL);
+	win_path = (char *) safemalloc(wlen+1);
+	wcsrtombs(win_path, (const wchar_t **)&wbuf, wlen, NULL);
+	if (oldlocale) setlocale(LC_CTYPE, oldlocale);
+	else setlocale(LC_CTYPE, "C");
+    } else {
+	int what = absolute_flag ? CCP_POSIX_TO_WIN_A : CCP_POSIX_TO_WIN_A | CCP_RELATIVE;
+	win_path = (char *) safemalloc(len + 260 + 1001);
+	err = cygwin_conv_path(what, src_path, win_path, len + 260 + 1001);
+	if (err == ENOSPC) { /* our space assumption was wrong, not enough space */
+	    int newlen = cygwin_conv_path(what, src_path, win_path, 0);
+	    win_path = (char *) realloc(&win_path, newlen);
+	    err = cygwin_conv_path(what, src_path, win_path, newlen);
+	}
+    }
+#else
+    if (isutf8)
+	Perl_warn(aTHX_ "can't convert utf8 path");
+    win_path = (char *) safemalloc(len + 260 + 1001);
     if (absolute_flag)
-	err = cygwin_conv_to_full_win32_path(pathname, buf);
+	err = cygwin_conv_to_full_win32_path(src_path, win_path);
     else
-	err = cygwin_conv_to_win32_path(pathname, buf);
+	err = cygwin_conv_to_win32_path(src_path, win_path);
+#endif
     if (!err) {
-	ST(0) = sv_2mortal(newSVpv(buf, 0));
-	safefree(buf);
-       XSRETURN(1);
+	EXTEND(SP, 1);
+	ST(0) = sv_2mortal(newSVpv(win_path, 0));
+	if (isutf8) {
+	    SvUTF8_on(ST(0));
+	}
+	safefree(win_path);
+	XSRETURN(1);
     } else {
-	safefree(buf);
+	safefree(win_path);
 	XSRETURN_UNDEF;
     }
 }
@@ -290,24 +444,22 @@
 {
     dXSARGS;
     char *pathname;
-    char flags[260];
+    char flags[PATH_MAX];
+    flags[0] = '\0';
 
     if (items != 1)
-        Perl_croak(aTHX_ "Usage: Cygwin::mount_flags(mnt_dir|'/cygwin')");
+        Perl_croak(aTHX_ "Usage: Cygwin::mount_flags( mnt_dir | '/cygdrive' )");
 
     pathname = SvPV_nolen(ST(0));
 
-    /* TODO: Check for cygdrive registry setting,
-     *       and then use CW_GET_CYGDRIVE_INFO
-     */
     if (!strcmp(pathname, "/cygdrive")) {
-	char user[260];
-	char system[260];
-	char user_flags[260];
-	char system_flags[260];
+	char user[PATH_MAX];
+	char system[PATH_MAX];
+	char user_flags[PATH_MAX];
+	char system_flags[PATH_MAX];
 
-	cygwin_internal (CW_GET_CYGDRIVE_INFO, user, system, user_flags,
-			 system_flags);
+	cygwin_internal (CW_GET_CYGDRIVE_INFO, user, system,
+			 user_flags, system_flags);
 
         if (strlen(user) > 0) {
             sprintf(flags, "%s,cygdrive,%s", user_flags, user);
@@ -320,6 +472,7 @@
 
     } else {
 	struct mntent *mnt;
+	int found = 0;
 	setmntent (0, 0);
 	while ((mnt = getmntent (0))) {
 	    if (!strcmp(pathname, mnt->mnt_dir)) {
@@ -328,12 +481,42 @@
 		    strcat(flags, ",");
 		    strcat(flags, mnt->mnt_opts);
 		}
+		found++;
 		break;
 	    }
 	}
 	endmntent (0);
-	ST(0) = sv_2mortal(newSVpv(flags, 0));
-	XSRETURN(1);
+
+	/* Check if arg is the current volume moint point if not default,
+	 * and then use CW_GET_CYGDRIVE_INFO also.
+	 */
+	if (!found) {
+	    char user[PATH_MAX];
+	    char system[PATH_MAX];
+	    char user_flags[PATH_MAX];
+	    char system_flags[PATH_MAX];
+
+	    cygwin_internal (CW_GET_CYGDRIVE_INFO, user, system,
+			     user_flags, system_flags);
+
+	    if (strlen(user) > 0) {
+		if (strcmp(user,pathname)) {
+		    sprintf(flags, "%s,cygdrive,%s", user_flags, user);
+		    found++;
+		}
+	    } else {
+		if (strcmp(user,pathname)) {
+		    sprintf(flags, "%s,cygdrive,%s", system_flags, system);
+		    found++;
+		}
+	    }
+	}
+	if (found) {
+	    ST(0) = sv_2mortal(newSVpv(flags, 0));
+	    XSRETURN(1);
+	} else {
+	    XSRETURN_UNDEF;
+	}
     }
 }
 
@@ -351,6 +534,8 @@
     XSRETURN(1);
 }
 
+XS(XS_Cygwin_sync_winenv){ cygwin_internal(CW_SYNC_WINENV); }
+
 void
 init_os_extras(void)
 {
@@ -366,6 +551,7 @@
     newXSproto("Cygwin::mount_table", XS_Cygwin_mount_table, file, "");
     newXSproto("Cygwin::mount_flags", XS_Cygwin_mount_flags, file, "$");
     newXSproto("Cygwin::is_binmount", XS_Cygwin_is_binmount, file, "$");
+    newXS("Cygwin::sync_winenv", XS_Cygwin_sync_winenv, file);
 
     /* Initialize Win32CORE if it has been statically linked. */
     handle = dlopen(NULL, RTLD_LAZY);
END
}

sub _patch_cygwin_ld2
{
	my @adjust = (
		[ qr/^5\.8\.[0-7]$/, sub { $_[0] =~ s/ \|\| \$Is_VMS//; } ],
		[ qr/^5\.8\.[0-5]$/, sub {
		# cygwin/Makefile.SHs
			$_[0] =~ s/\@\@ -22,73/@@ -22,72/;
			$_[0] =~ s/-\t\@chmod a\+x ld2\n//;
		} ],
		[ qr/^5\.8\.[0-2]$/, sub {
		# cygwin/Makefile.SHs
			$_[0] =~ s/\@\@ -22,72/@@ -22,71/;
			$_[0] =~ s/these ones are mandatory/this one is pretty mandatory/;
			$_[0] =~ s/-VERSION = '\$version'\n//;
			$_[0] =~ s/ -e s,\@VERSION\@,\\\${VERSION},g//;
		} ],
		[ qr/^5\.8\.0$/, sub {
		# Makefile.SH
			$_[0] =~ s/ pad\$\(OBJ_EXT\)//;
			$_[0] =~ s/ opmini\.c//;
			$_[0] =~ s/ \$\(obj\) \$\(libs\)/ \$(obj)/;
		} ],
	);
	my $patch = <<'END'; $_->[1]->($patch) for grep { Devel::PatchPerl::_is( $_->[0], $_[0] ) } @adjust; Devel::PatchPerl::_patch($patch);
--- cygwin/Makefile.SHs.orig	2004-09-10 18:30:39.000000000 +0900
+++ cygwin/Makefile.SHs	2008-03-12 05:46:24.000000000 +0900
@@ -3,8 +3,8 @@
 
 # Rerun `sh Makefile.SH; make depend' after making any change.
 
-# Additional rules supported: libperls.a (for static linking),
-# ld2, perlld (dynamic linking tools)
+# Additional rules supported: libperl.a (for static linking),
+# ld2 and perlld removed
 #
 
 #! /bin/sh
@@ -22,73 +22,33 @@
 	;;
 esac
 
-addtopath=`pwd`
+addtopath=`pwd | sed -e 's/ /\\\ /g'`
 $spitshell >>Makefile <<!GROK!THIS!
 
 cygwin.c: cygwin/cygwin.c
 	\$(LNS) cygwin/cygwin.c
 
-# shell script feeding perlld to decent perl
-ld2: $& Makefile perlld ${src}/cygwin/ld2.in
-	@echo "extracting ld2 (with variable substitutions)"
-	@$sed s,@buildpath@,$addtopath,g <${src}/cygwin/ld2.in >ld2
-	@chmod a+x ld2
-	@echo "installing ld2 into $installbin"
-# install is included in Cygwin distributions, and we make a note of th
-# requirement in the README.cygwin file. However, let's give them
-# a warning.
-	@/usr/bin/install -c -m 755 ld2 ${installbin}/ld2
-	@if test ! -f  ${installbin}/ld2; then \
-		echo "*************************************************" ; \
-		echo "Make will probably fail in a few more steps." ; \
-		echo "When it does, copy \"ld2\" to a directory in" ; \
-		echo "your path, other than \".\"." ; \
-		echo "\"/usr/local/bin\" or something similar will do." ; \
-		echo "Then restart make." ; \
-		echo "*************************************************" ; \
-	fi
-
-!GROK!THIS!
-
-$spitshell >>Makefile <<!GROK!THIS!
-
-# perlld parameters
-#
-# these ones are mandatory
-DLLWRAP = 'dllwrap'
-VERSION = '$version'
-
-# following are optional.
-WRAPDRIVER = gcc
-DLLTOOL = dlltool
-EXPORT_ALL = 1
-
-# if some of extensions are empty,
-# no corresponding output will be done.
-# most probably, you'd like to have an export library
-DEF_EXT = .def
-EXP_EXT = .exp
-
-perlld: $& Makefile ${src}/cygwin/perlld.in
-	@echo "extracting perlld (with variable substitutions)"
-	@$sed -e s,@CC@,\${CC}, -e s,@DLLWRAP@,\${DLLWRAP},g \\
-	-e s,@WRAPDRIVER@,\${WRAPDRIVER},g -e s,@DLLTOOL@,\${DLLTOOL},g \\
-	-e s,@AS@,\${AS},g -e s,@EXPORT_ALL@,\${EXPORT_ALL},g \\
-	-e s,@DEF_EXT@,\${DEF_EXT},g -e s,@EXP_EXT@,\${EXP_EXT},g \\
-	-e s,@LIB_EXT@,\${LIB_EXT},g -e s,@VERSION@,\${VERSION},g \\
-	${src}/cygwin/perlld.in >perlld
-
 !GROK!THIS!
 
 # make sure that all library names are not malformed
 libperl=`echo $libperl|sed -e s,\\\..*,,`
-
 linklibperl=-l`echo $libperl|sed -e s,^lib,,`
+vers=`echo $version|tr '.' '_'`
+dllname=`echo $libperl|sed -e s,^lib,cyg,``echo $vers|sed -e s,_[0-9]$,,`
+# append "d" suffix to -DDEBUGGING build: cygperl5_10d.dll
+case $config_args in
+  *DEBUGGING*)
+      dllname="${dllname}"d
+      ;;
+esac
 
 $spitshell >>Makefile <<!GROK!THIS!
 LIBPERL = $libperl
 LLIBPERL= $linklibperl
+DLLNAME= $dllname
 CLDFLAGS= -L$addtopath $ldflags
+LDDLFLAGS = --shared -L$addtopath $ldflags
+PLDLFLAGS = 
 CAT = $cat
 AWK = $awk
 !GROK!THIS!
@@ -104,13 +64,13 @@
 
 # library used to make statically linked executables
 # miniperl is linked against it to avoid libperl.dll locking
-$(LIBPERL)$(LIB_EXT): $& perl$(OBJ_EXT) $(cwobj)
-	$(AR) rcu $@ perl$(OBJ_EXT) $(cwobj)
+$(LIBPERL)$(LIB_EXT): $& $(cwobj)
+	$(AR) rcu $@ $(cwobj)
 
 # dll and import library
-$(LIBPERL).dll$(LIB_EXT): $& perl$(OBJ_EXT) $(cwobj) ld2
-	$(LDLIBPTH) ld2 $(SHRPLDFLAGS) -o $(LIBPERL)$(DLSUFFIX) \
-	perl$(OBJ_EXT) $(cwobj) $(libs)
+$(LIBPERL).dll$(LIB_EXT): $& $(cwobj)
+	$(LDLIBPTH) $(CC) $(SHRPLDFLAGS) -o $(DLLNAME)$(DLSUFFIX) -Wl,--out-implib=$@ \
+	$(cwobj) $(libs)
 
 # How to build executables.
 
@@ -122,7 +82,7 @@
 
 miniperl.exe \
 miniperl: $& miniperlmain$(OBJ_EXT) $(LIBPERL)$(LIB_EXT) opmini$(OBJ_EXT)
-	$(LDLIBPTH) $(CC) $(CLDFLAGS) -o miniperl miniperlmain$(OBJ_EXT) opmini$(OBJ_EXT) $(LLIBPERL) $(libs)
+	$(LDLIBPTH) $(CC) $(CLDFLAGS) -o miniperl miniperlmain$(OBJ_EXT) opmini$(OBJ_EXT) $(LIBPERL)$(LIB_EXT) $(libs)
 	$(LDLIBPTH) ./miniperl -w -Ilib -MExporter -e '<?>' || $(MAKE) minitest
 
 perl.exe \
@@ -145,8 +105,8 @@
 cwobj = $(obj)
 
 # perl library
-$(LIBPERL)$(LIB_EXT): $& perl$(OBJ_EXT) $(cwobj)
-	$(AR) rcu $@ perl$(OBJ_EXT) $(cwobj)
+$(LIBPERL)$(LIB_EXT): $& $(cwobj)
+	$(AR) rcu $@ $(cwobj)
 
 # How to build executables.
 
@@ -202,7 +162,9 @@
 
 distdir: miniperl
 	-mkdir $(DIST_DIRECTORY)
-	./miniperl '-MExtUtils::Manifest' \
+	./miniperl -Ilib '-MExtUtils::Manifest' \
 	-e "ExtUtils::Manifest::manicopy(ExtUtils::Manifest::maniread(),'$(DIST_DIRECTORY)')"
 
+test_prep: 
+
 !NO!SUBS!
--- hints/cygwin.sh.orig	2014-05-12 01:31:55.334217700 +0900
+++ hints/cygwin.sh	2014-05-12 01:32:24.439127900 +0900
@@ -63,11 +63,11 @@
 esac
 
 # compile Win32CORE "module" as static. try to avoid the space.
-if test -z "$static_ext"; then
-  static_ext="Win32CORE"
-else
-  static_ext="$static_ext Win32CORE"
-fi
+#if test -z "$static_ext"; then
+#  static_ext="Win32CORE"
+#else
+#  static_ext="$static_ext Win32CORE"
+#fi
 
 # Win9x problem with non-blocking read from a closed pipe
 d_eofnblk='define'
--- Makefile.SH.orig	2006-01-24 21:49:44.000000000 +0900
+++ Makefile.SH	2014-05-12 02:22:56.994353100 +0900
@@ -361,7 +361,7 @@
 c = $(c1) $(c2) $(c3) $(c4) miniperlmain.c perlmain.c opmini.c
 
 obj1 = $(mallocobj) gv$(OBJ_EXT) toke$(OBJ_EXT) perly$(OBJ_EXT) op$(OBJ_EXT) pad$(OBJ_EXT) regcomp$(OBJ_EXT) dump$(OBJ_EXT) util$(OBJ_EXT) mg$(OBJ_EXT) reentr$(OBJ_EXT)
-obj2 = hv$(OBJ_EXT) av$(OBJ_EXT) run$(OBJ_EXT) pp_hot$(OBJ_EXT) sv$(OBJ_EXT) pp$(OBJ_EXT) scope$(OBJ_EXT) pp_ctl$(OBJ_EXT) pp_sys$(OBJ_EXT)
+obj2 = hv$(OBJ_EXT) av$(OBJ_EXT) perl$(OBJ_EXT) run$(OBJ_EXT) pp_hot$(OBJ_EXT) sv$(OBJ_EXT) pp$(OBJ_EXT) scope$(OBJ_EXT) pp_ctl$(OBJ_EXT) pp_sys$(OBJ_EXT)
 obj3 = doop$(OBJ_EXT) doio$(OBJ_EXT) regexec$(OBJ_EXT) utf8$(OBJ_EXT) taint$(OBJ_EXT) deb$(OBJ_EXT) universal$(OBJ_EXT) xsutils$(OBJ_EXT) globals$(OBJ_EXT) perlio$(OBJ_EXT) perlapi$(OBJ_EXT) numeric$(OBJ_EXT) locale$(OBJ_EXT) pp_pack$(OBJ_EXT) pp_sort$(OBJ_EXT)
 
 obj = $(obj1) $(obj2) $(obj3) $(ARCHOBJS)
@@ -496,9 +496,9 @@
 LIBPERL_NONSHR		= libperl_nonshr$(LIB_EXT)
 MINIPERL_NONSHR		= miniperl_nonshr$(EXE_EXT)
 
-$(LIBPERL_NONSHR): perl$(OBJ_EXT) $(obj)
+$(LIBPERL_NONSHR): $(obj)
 	$(RMS) $(LIBPERL_NONSHR)
-	$(AR) rcu $(LIBPERL_NONSHR) perl$(OBJ_EXT) $(obj)
+	$(AR) rcu $(LIBPERL_NONSHR) $(obj)
 
 $(MINIPERL_NONSHR): $(LIBPERL_NONSHR) miniperlmain$(OBJ_EXT) opmini$(OBJ_EXT)
 	$(CC) $(LDFLAGS) -o $(MINIPERL_NONSHR) miniperlmain$(OBJ_EXT) \
@@ -545,12 +545,12 @@
 !GROK!THIS!
 else
 	$spitshell >>Makefile <<'!NO!SUBS!'
-$(LIBPERL): $& perl$(OBJ_EXT) $(obj) $(LIBPERLEXPORT)
+$(LIBPERL): $& $(obj) $(LIBPERLEXPORT)
 !NO!SUBS!
 	case "$useshrplib" in
 	true)
 		$spitshell >>Makefile <<'!NO!SUBS!'
-	$(LD) -o $@ $(SHRPLDFLAGS) perl$(OBJ_EXT) $(obj) $(libs)
+	$(LD) -o $@ $(SHRPLDFLAGS) $(obj) $(libs)
 !NO!SUBS!
 		case "$osname" in
 		aix)
@@ -565,7 +565,7 @@
 	*)
 		$spitshell >>Makefile <<'!NO!SUBS!'
 	rm -f $(LIBPERL)
-	$(AR) rcu $(LIBPERL) perl$(OBJ_EXT) $(obj)
+	$(AR) rcu $(LIBPERL) $(obj)
 	@$(ranlib) $(LIBPERL)
 !NO!SUBS!
 		;;
@@ -590,7 +590,7 @@
 miniperl: $& miniperlmain$(OBJ_EXT) $(LIBPERL) opmini$(OBJ_EXT)
 	$(CC) -o miniperl $(CLDFLAGS) \
 	    `echo $(obj) | sed 's/ op$(OBJ_EXT) / /'` \
-	    miniperlmain$(OBJ_EXT) opmini$(OBJ_EXT) perl$(OBJ_EXT) $(libs)
+	    miniperlmain$(OBJ_EXT) opmini$(OBJ_EXT) $(libs)
 	$(LDLIBPTH) ./miniperl -w -Ilib -MExporter -e '<?>' || $(MAKE) minitest
 !NO!SUBS!
 		;;
@@ -598,7 +598,7 @@
 		$spitshell >>Makefile <<'!NO!SUBS!'
 miniperl: $& miniperlmain$(OBJ_EXT) $(LIBPERL) opmini$(OBJ_EXT)
 	$(CC) -o miniperl `echo $(obj) | sed 's/ op$(OBJ_EXT) / /'` \
-	    miniperlmain$(OBJ_EXT) opmini$(OBJ_EXT) perl$(OBJ_EXT) $(libs)
+	    miniperlmain$(OBJ_EXT) opmini$(OBJ_EXT) $(libs)
 	$(LDLIBPTH) ./miniperl -w -Ilib -MExporter -e '<?>' || $(MAKE) minitest
 !NO!SUBS!
 		;;
END

	if($_[0] =~ /^5\.8\.[1-8]$/) {
		my @adjust = (
			[ qr/^5\.8\.[1-7]/, sub { $_[0] =~ s/ \|\| \$Is_VMS//; } ],
			[ qr/^5\.8\.[1-4]/, sub {
				$_[0] =~ s/\@\@ -260,40/@@ -260,39/;
				$_[0] =~ s/-\t\t\$packlist->.*\n//;
			} ],
		);
		my $patch = <<'END'; $_->[1]->($patch) for grep { Devel::PatchPerl::_is( $_->[0], $_[0] ) } @adjust; Devel::PatchPerl::_patch($patch);
--- installperl.orig	2006-01-29 00:35:28.000000000 +0900
+++ installperl	2014-05-12 02:41:30.833722700 +0900
@@ -260,40 +260,9 @@
 
     if ($Is_Cygwin) {
 	$perldll = $libperl;
-	my $v_e_r_s = $ver; $v_e_r_s =~ tr/./_/;
+	my $v_e_r_s = substr($ver,0,-2); $v_e_r_s =~ tr/./_/;
 	$perldll =~ s/(\..*)?$/$v_e_r_s.$dlext/;
 	$perldll =~ s/^lib/cyg/;
-	if ($Config{useshrplib} eq 'true') {
-	    # install ld2 and perlld as well
-	    foreach ('ld2', 'perlld') {
-		safe_unlink("$installbin/$_");
-		copy("$_", "$installbin/$_");
-		chmod(0755, "$installbin/$_");
-		$packlist->{"$installbin/$_"} = { type => 'file' };
-	    };
-	    open (LD2, ">$installbin/ld2");
-	    print LD2 <<SHELL;
-#!/bin/sh
-#
-# ld wrapper, passes all args to perlld;
-#
-for trythis in $installbin/perl
-do
-  if [ -x \$trythis ]
-  then
-    \$trythis $installbin/perlld "\$\@"
-    exit \$?
-  fi
-done
-# hard luck!
-echo I see no perl executable around there
-echo perl is required to build dynamic libraries
-echo look if the path to perl in /bin/ld2 is correct
-exit 1
-SHELL
-	    close LD2;
-	    chmod(0755, "$installbin/ld2");
-	};
     } else {
 	$perldll = 'perl58.' . $dlext;
     }
@@ -376,6 +345,7 @@
 # Install library files.
 
 my ($do_installarchlib, $do_installprivlib) = (0, 0);
+my $vershort = $Is_Cygwin ? substr($ver,0,-2) : $ver;
 
 mkpath($installprivlib, $verbose, 0777);
 mkpath($installarchlib, $verbose, 0777);
@@ -385,7 +355,7 @@
 if (chdir "lib") {
     $do_installarchlib = ! samepath($installarchlib, '.');
     $do_installprivlib = ! samepath($installprivlib, '.');
-    $do_installprivlib = 0 if $versiononly && !($installprivlib =~ m/\Q$ver/);
+    $do_installprivlib = 0 if $versiononly && !($installprivlib =~ m/\Q$vershort/);
 
     if ($do_installarchlib || $do_installprivlib) {
 	find(\&installlib, '.');
@@ -589,7 +559,7 @@
 # ($installprivlib/pods for cygwin).
 
 my $pod = ($Is_Cygwin || $Is_Darwin || $Is_VMS) ? 'pods' : 'pod';
-if ( !$versiononly || ($installprivlib =~ m/\Q$ver/)) {
+if ( !$versiononly || ($installprivlib =~ m/\Q$vershort/)) {
     mkpath("${installprivlib}/$pod", $verbose, 0777);
 
     # If Perl 5.003's perldiag.pod is there, rename it.
END
	} else {
		Devel::PatchPerl::_patch(<<'END');
--- installperl.orig	2002-07-17 03:57:32.000000000 +0900
+++ installperl	2014-05-12 11:10:17.032674700 +0900
@@ -234,29 +234,9 @@
 
   if ($Is_Cygwin) {
     $perldll = $libperl;
-    my $v_e_r_s = $ver; $v_e_r_s =~ tr/./_/;
+    my $v_e_r_s = substr($ver,0,-2); $v_e_r_s =~ tr/./_/;
     $perldll =~ s/(\..*)?$/$v_e_r_s.$dlext/;
     $perldll =~ s/^lib/cyg/;
-    if ($Config{useshrplib} eq 'true') {
-      # install ld2 and perlld as well
-      foreach ('ld2', 'perlld') {
-        safe_unlink("$installbin/$_");
-        copy("$_", "$installbin/$_");
-        chmod(0755, "$installbin/$_");
-      };
-      { 
-		open (LD2, ">$installbin/ld2");
-		print LD2 "#!/bin/sh\n#\n# ld wrapper, passes all args to perlld;\n#\n"
-		          . "for trythis in $installbin/perl\ndo\n  if [ -x \$trythis ]\n"
-		          . "  then\n    \$trythis $installbin/perlld \"\$\@\"\n"
-		          . "    exit \$?\n  fi\ndone\n# hard luck!\necho i see no perl"
-		          . " executable around there\necho perl is required to build "
-		          . "dynamic libraries\necho look if the path to perl in /bin/ld2"
-		          . " is correct\nexit 1\n";
-		close LD2;
-      };
-      chmod(0755, "$installbin/ld2");
-    };
   } else {
     $perldll = 'perl58.' . $dlext;
   }
@@ -331,6 +311,7 @@
 # Install library files.
 
 my ($do_installarchlib, $do_installprivlib) = (0, 0);
+my $vershort = $Is_Cygwin ? substr($ver,0,-2) : $ver;
 
 mkpath($installprivlib, $verbose, 0777);
 mkpath($installarchlib, $verbose, 0777);
@@ -340,7 +321,7 @@
 if (chdir "lib") {
     $do_installarchlib = ! samepath($installarchlib, '.');
     $do_installprivlib = ! samepath($installprivlib, '.');
-    $do_installprivlib = 0 if $versiononly && !($installprivlib =~ m/\Q$ver/);
+    $do_installprivlib = 0 if $versiononly && !($installprivlib =~ m/\Q$vershort/);
 
     if ($do_installarchlib || $do_installprivlib) {
 	find(\&installlib, '.');
END
	}
}

1

__END__

=pod

=head1 NAME

Devel::PatchPerl::Plugin::Cygwin - Devel::PatchPerl plugin for Cygwin

=head1 VERSION

version v0.0.1

=head1 SYNOPSIS

  # for bash etc.
  $ export PERL5_PATCHPERL_PLUGIN=Cygwin
  # for tcsh etc.
  % setenv PERL5_PATCHPERL_PLUGIN Cygwin

  # After that, use patchperl, for example, via perlbrew
  $ perlbrew install perl-5.10.1

=head1 DESCRIPTION

This module is a plugin module for L<Devel::PatchPerl> for the Cygwin environment.
It might be better to be included in original because it is not for variant but for environment.
The Cygwin environment is, however, relatively minor and tricky environment.
So, this module is provided as a plugin in order to try patches unofficially and experimentally.

All stable releases on and after 5.8 serires are compilable.

=head1 METHODS

=head2 patchperl

A class method of plugin interface for L<Devel::PatchPerl>. See L<Devel::PatchPerl::Plugin>.

=head1 TESTS

If you want to check if patches succeed for all stable releases on and after 5.8 series,
specify the environment variables C<PERL5_DPPPC_PATCH_TESTING> and C<AUTHOR_TESTING> when testing.

If you have dist tarballs in your perlbrew root, they are used.
Otherwise they are downloaded into a temporary directory for each invoking test.

=head1 CAVEAT

L<Devel::PatchPerl> says as the following:

=over 4

L<Devel::PatchPerl> is intended only to facilitate the "building" of
perls, not to facilitate the "testing" of perls. This means that it
will not patch failing tests in the perl testsuite.

=back

This statement is applicable also for this plugin.
For example, on some versions of perls, it is observed that tests such as op/taint.t and op/threads.t are blocked at the author's environment.

=head1 SEE ALSO

=over 4

=item *

L<Devel::PatchPerl::Plugin>

=item *

L<App::perlbrew>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
