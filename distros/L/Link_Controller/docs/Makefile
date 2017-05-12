standard: info inst readme html pdf

all: ps ps2 info dvi inst standard

.PHONY: all standard html ps ps2 dvi readme inst clean distclean realclean

html: HTML/link-controller_toc.html

HTML/link-controller_toc.html: link-controller.texinfo
	(cd HTML; texi2html -split_chapter ../link-controller.texinfo)

pdf: link-controller.pdf

link-controller.pdf: link-controller.texinfo
	texi2pdf link-controller.texinfo

ps: link-controller.ps

link-controller.ps: link-controller.dvi
	dvips link-controller.dvi -o link-controller.ps

ps2: link-controller.ps2

link-controller.ps2: link-controller.ps
	mpage -2 -o link-controller.ps > link-controller.ps2

dvi : link-controller.dvi

link-controller.dvi: link-controller.texinfo
	texi2dvi link-controller.texinfo

info: link-controller.info

link-controller.info: link-controller.texinfo
	makeinfo link-controller.texinfo

readme: ../README

../README: README.html
	pod2text --loose README.pod > ../README


README.html: README.pod
	pod2html README.pod > README.html

#not install to avoid confusion

inst: ../INSTALL

../INSTALL: INSTALL.html
	pod2text --loose INSTALL.pod > ../INSTALL

INSTALL.html: INSTALL.pod
	pod2html --title "LinkController Installation Instructions" \
		INSTALL.pod > INSTALL.html

# keep the HTML file, delete the rest.. most people who can use them
# will be able to generate them..  Distribute ps file separately since
# it's big, but not everyone who wants it will be able to generate it.

clean:
	rm -f link-controller.cp link-controller.cps link-controller.fn\
	      link-controller.ky link-controller.log link-controller.pg\
	      link-controller.toc link-controller.tp link-controller.vr\
	      link-controller.vrs link-controller.aux

distclean: clean
	rm -f INSTALL.html README.html link-controller.ps \
	      link-controller.ps2 link-controller.dvi

realclean: distclean
	rm -f link-controller.pdf link-controller.info HTML/*.html


