# Copyright 2017, 2021 Kevin Ryde

# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.


default: pictures.pdf
all: pictures.pdf

pictures.pdf: pictures.tex
	latexmk -file-line-error -pdf pictures.tex

clean:
	rm -f pictures.aux pictures.fls pictures.log pictures.out
	rm -f pictures.dvi pictures.pdf *.fdb_latexmk
	rm -rf _whizzy*
