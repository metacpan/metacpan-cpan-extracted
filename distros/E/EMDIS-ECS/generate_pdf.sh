#!/bin/sh
#
# Copyright (C) 2004-2016 National Marrow Donor Program. All rights reserved.
#
# generate_pdf.sh - generate PDF documentation
#
# This script requires the presence of a TeX implementation, such as teTeX:
# http://tug.org/teTeX/.
# 
# TODO:  integrate this procedure with Makefile.PL

if [ -z "$1" ]; then
  echo "Error - <version> not specified."
  echo "Usage:  $0 <version>"
  exit 1
fi

# convert embedded POD documentation to LaTeX
pod2latex -out perlecs.tex -full -modify script/ecs_chk_com script/ecs_ctl \
 script/ecs_pid_chk script/ecs_proc_meta script/ecs_proc_msg \
 script/ecs_scan_mail script/ecs_setup script/ecs_token script/ecstool \
 lib/EMDIS/ECS.pm \
 lib/EMDIS/ECS/Config.pm lib/EMDIS/ECS/FileBackedMessage.pm \
 lib/EMDIS/ECS/LockedHash.pm lib/EMDIS/ECS/Message.pm

# add title and version
perl -n -i -e "\$version='$1';" -e 's/<(\S+)>/\\textless{}$1\\textgreater{}/go; print; /\\begin{document}/o and print "\\begin{flushleft}\\huge\\textbf{Perl ECS}\\par\\normalsize Version $version\\end{flushleft}\n";' perlecs.tex

# convert LaTeX to DVI
latex perlecs.tex
# run LaTeX again to update DVI tableofcontents
latex perlecs.tex

# convert DVI to PDF
dvipdfm perlecs.dvi
