MPOST = /usr/bin/mpost
NAME = sgf2mpost
VERSION = 1.0

FIGURES = figure1.1 figure2.1 figure3.1 figure4.1 figure5.1 figure6.1 \
	  figure7.1 figure8.1 figure9.1 figure10.1 figure10a.1
MPOSTFILES = figure1.mp figure2.mp figure3.mp figure4.mp figure5.mp figure6.mp\
	   figure7.mp figure8.mp figure9.mp figure10.mp figure10a.mp
SGFFILES = game1.sgf game2.sgf vars.sgf game3.sgf game4.sgf

.SUFFIXES: .ps .pdf .dvi .tex

.tex.dvi:
	tex $<

.dvi.ps:
	dvips -o $@ $<

.ps.pdf:
	gs -sDEVICE=pdfwrite -sOutputFile=$@ -dNOPAUSE $< </dev/null

sgf2mpost: sgf2mpost.c
	   cc -g -o sgf2mpost sgf2mpost.c

install:
	cp sgf2mpost /usr/local/bin

again:
	make metapostfiles;
	make figures;

eps: $(FIGURES)
	list='$(FIGURES)'; \
	for i in $$list; do \
	echo "Making $$i.eps"; \
	mps2eps $$i; \
	done;

metapostfiles $(MPOSTFILES):
	sgf2mpost -i game1.sgf -o figure1.mp -e E14 -L a:R15 -L b:P9 -L c:F13 -S 0.85 -I cmbxti10
	sgf2mpost -i vars.sgf -o figure2.mp -r 9 -b 7 -S 0.85 -F cmbx10
	sgf2mpost -i game1.sgf -o figure3.mp -b 7 -s 57 -S 0.90 -F cmr10 -B cmr8
	sgf2mpost -i game2.sgf -o figure4.mp -e 155 -S .85 -F cmr8 -B cmr8
	sgf2mpost -i game2.sgf -o figure5.mp -s 156 -e 168 -n 56 -S .85 -t 13
	sgf2mpost -i game2.sgf -o figure6.mp -s 169 -e 186 -n 69 -S .85 -t 13
	sgf2mpost -i game2.sgf -o figure7.mp -s 187 -e 202 -n 87 -S .85 -B "cmr8" -l 4 -t 11
	sgf2mpost -i game2.sgf -o figure8.mp -s 203 -n 3 -S .85 -l 4 -t 16
	sgf2mpost -i game3.sgf -o figure9.mp -s234 -e234 -r 11 -b 9 -n 1 -T B14 -T C16 -T C15 -T C14 -T D13 -T E13 -T E12 -T F11 -T G12 -T G13 -T G14
	sgf2mpost -i game4.sgf -o figure10.mp -S .75 -F cmr8 -B cmr6 -e 100
	sgf2mpost -i game4.sgf -o figure10a.mp -S .75 -F cmr8 -B cmr6 -s 101 -n 1
	
figures $(FIGURES): $(MPOSTFILES) sgf2mpost
	$(MPOST) figure1.mp
	$(MPOST) figure2.mp
	$(MPOST) figure3.mp
	$(MPOST) figure4.mp
	$(MPOST) figure5.mp
	$(MPOST) figure6.mp
	$(MPOST) figure7.mp
	$(MPOST) figure8.mp
	$(MPOST) figure9.mp
	$(MPOST) figure10.mp
	$(MPOST) figure10a.mp
