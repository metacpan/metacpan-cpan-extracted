# Copyright 2020 Kevin Ryde

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


all pdf: MostMaximumMatchingsTree-samples.pdf

MostMaximumMatchingsTree-samples.pdf: MostMaximumMatchingsTree-samples.tex
	latexmk -pdf MostMaximumMatchingsTree-samples.tex
	qpdf --linearize \
	  --stream-data=compress \
	  --compress-streams=y \
	  --compression-level=9 \
	  MostMaximumMatchingsTree-samples.pdf tempfile-qpdf.pdf
	mv tempfile-qpdf.pdf MostMaximumMatchingsTree-samples.pdf 
	qpdf --check MostMaximumMatchingsTree-samples.pdf
	if grep 'Missing character' MostMaximumMatchingsTree-samples.log; then exit 1; fi
	ls -l MostMaximumMatchingsTree-samples.pdf

check test:
	../../shared/my-check-tex.pl MostMaximumMatchingsTree-samples.tex
	../../dragon/tools/test-gen-output.pl MostMaximumMatchingsTree-samples.tex

clean:
	rm -f *.png
	rm -f *.s6
	rm -f MostMaximumMatchingsTree-samples.aux
	rm -f MostMaximumMatchingsTree-samples.fdb_latexmk
	rm -f MostMaximumMatchingsTree-samples.fls
	rm -f MostMaximumMatchingsTree-samples.log
	rm -f MostMaximumMatchingsTree-samples.out
	rm -f MostMaximumMatchingsTree-samples.pdf
	rm -rf _whizzy_MostMaximumMatchingsTree-samples_d

#------------------------------------------------------------------------------
.PHONY: all check clean test
