# DESCRIPTION: Dir::Project: Makefile include to define DIRPROJECT envvar
######################################################################
#
# Copyright 2001-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
######################################################################

ifndef _DIRPROJECT_MK_
  _DIRPROJECT_MK_ = 1

  ifndef _DIRPROJECT_MKFILE_
     # first time, not called from a submake, so generate the variables
     # Call project bin, it will generate an include file and return the
     # filename.
     DIRPROJECT_PROJECTDIREXE ?= project_dir
     _DIRPROJECT_MKFILE_ := $(shell $(DIRPROJECT_PROJECTDIREXE) --makefile)
     export _DIRPROJECT_MKFILE_
     # Include the file it requested
     include $(_DIRPROJECT_MKFILE_)
  endif

  # Remove this file at the end
  .INTERMEDIATE: $(_DIRPROJECT_MKFILE_)

endif
