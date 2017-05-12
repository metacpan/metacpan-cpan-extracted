# Makefile for EPL (Emacs Perl) XEmacs package
# CVS check out xemacs-packages (see www.xemacs.org), do cvs update
# (see comments), copy Local.rules.template to Local.rules, rename the
# Emacs-EPL-x.x directory "epl", move it to xemacs-packages/libs/,
# apply the patch at the end of this file to
# xemacs-packages/package-compile.el, execute "make -f xemacs/Makefile
# dist" in the epl directory, and find your binary package in
# xemacs-packages/../Packages.

# Copyright (C) 2001 by John Tobey,
# jtobey@john-edwin-tobey.org.  All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to the
#   Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
#   MA 02111-1307  USA

VERSION = 1.03
AUTHOR_VERSION = $(shell perl Makefile.PL print_package_version)
MAINTAINER = John Tobey <jtobey@john-edwin-tobey.org>
PACKAGE = epl
PKG_TYPE = regular
REQUIRES = epl xemacs-base
CATEGORY = libs

EXTRA_SOURCES = README COPYING

LISPFILES = $(shell grep '\.el$$' MANIFEST)
ELCS = $(LISPFILES:.el=.elc)

INFO_FILES = doc/$(PACKAGE).info*
TEXI_FILES = doc/epl.texi doc/fdl.texi doc/version.texi
MAKEINFO_FLAGS = -I doc

DATA_FILES = $(wildcard lib/*.pm)
DATA_DEST = perllib
DATA_1_FILES = $(wildcard lib/Emacs/*.pm)
DATA_1_DEST = perllib/Emacs

AUTOLOAD_PATH = lisp

include ../../XEmacs.rules

all:: $(AUTOLOAD_PATH)/auto-autoloads.elc $(ELCS) doc/$(PACKAGE).info

doc/epl.info: $(TEXI_FILES)
	makeinfo -I doc -o $@ doc/epl.texi

doc/version.texi: Makefile.PL lisp/epl.el
	perl Makefile.PL write_version_texi

srckit: doc/version.texi srckit-std

binkit: binkit-common

package-info.in: xemacs/package-info.in
	cp $< $@

.PHONY: Makefile

Makefile: xemacs/Makefile

clean::
	rm -f package-info.in

# How to patch the xemacs-packages CVS tree to build this package:

# Index: package-compile.el
# ===================================================================
# RCS file: /usr/CVSroot/XEmacs/xemacs-packages/package-compile.el,v
# retrieving revision 1.24
# diff -u -2 -r1.24 package-compile.el
# --- package-compile.el	2001/01/19 05:30:11	1.24
# +++ package-compile.el	2001/01/30 18:25:34
# @@ -70,4 +70,5 @@
#      ("efs" . "libs")
#      ("elib" . "libs")
# +    ("epl" . "libs")
#      ("fsf-compat" . "libs")
#      ("mail-lib" . "libs")
# @@ -170,4 +171,5 @@
#  	  ((or (equal package "w3") 
#  	       (equal package "bbdb") 
# +	       (equal package "epl")
#  	       (equal package "jde")
#  	       (equal package "lookup"))
