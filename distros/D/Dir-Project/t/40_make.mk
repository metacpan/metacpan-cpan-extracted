#!/usr/bin/perl -w
# DESCRIPTION: Example makefile for project_dir.mk
#
# Copyright 2006-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

include $(DIRPROJECT_PREFIX)/lib/project_dir.mk
default:
	@echo $(DIRPROJECT)
