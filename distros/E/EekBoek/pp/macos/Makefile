#! /bin/make -f

# GNUmakefile for MacOS, Citrus Perl

default : dmg

.PHONY :: ebshell ebwxshell

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
DEST   := build

PP := pp -u

# PAR Packer.

ebshell : ebshell.pp ${COMMON}/ebshell.pp
	${PP} --output=ebshell @ebshell.pp ${SCRIPT}/ebshell.pl

ebwxshell : ebshell.pp ${COMMON}/ebshell.pp ${COMMON}/ebwxshell.pp
	${PP} --output=ebwxshell @ebwxshell.pp ${SCRIPT}/ebwxshell.pl

clean ::
	rm -f *.pp.deps *~ ebshell ebwxshell

# Portable Perl Launcher

PERLLIB := $(shell perl -MConfig -E 'say $$Config{archlib}')
PERLINC := ${PERLLIB}/perl5/CORE
PERLSO  := $(shell perl -MConfig -E 'say $$Config{libperl}')

.PHONY :: ppl
ppl :: clean ebshell ebwxshell unpack copy_coredll loaders

.PHONY :: unpack
unpack :
	perl ../pp2ppl.pl --dest=${DEST} ebwxshell --quiet
	perl ../pp2ppl.pl --dest=${DEST} ebshell   --quiet
	cp "${DEST}/res/Wx/icons/eb.icns" ${DEST}/eb.icns
	cp "${DEST}/res/Wx/icons/eb.icns" ${DEST}/eb-doc.icns
	mv "${DEST}/res" "${DEST}/lib/EB/"
	rm -f "${DEST}/script/main.pl"

# Copy core DLLs.
# We assume that the target system has the primary ddls like -ldl, -lc, ...
copy_coredll :
	cp -pL ${PERLLIB}/../citrus/dll/libperl.dylib ${DEST}/${PERLSO}
	install_name_tool -id  @executable_path/${PERLSO} ${DEST}/${PERLSO}

PREFIX := '"script/"'
CCOPTS := $(shell perl -MExtUtils::Embed -e ccopts) -DSCRIPTPREFIX=${PREFIX}
LDOPTS := ${DEST}/${PERLSO} -lpthread
WXCLIB := ${HOME}/lib/citrusperl/vendor/lib/Alien/wxWidgets/osx_cocoa_3_0_2_uni
WXCNFG := ${WXCLIB}/bin/wx-config

.PHONY :: loaders
loaders : "${DEST}/ebwxshell" "${DEST}/ebshell"

# For testing...
.PHONY :: _loaders
_loaders : "${DEST}/ebshell"
	cp "${DEST}/ebshell" "${DEST}/perl"

"${DEST}/ebwxshell" : ppl.c dndhandler.cpp
	${CC} ${CCOPTS} -o "${DEST}/ebwxshell" -L${DEST} ${LDOPTS} ppl.c
	${CXX} -o "${DEST}/dndhandler" \
		dndhandler.cpp `${WXCNFG} --cxxflags --libs`
	perl ./reloc.pl "${DEST}/dndhandler"

"${DEST}/ebshell" : ppl.c
	${CC} ${CCOPTS} -o "${DEST}/ebshell" -L${DEST} ${LDOPTS} ppl.c

clean ::
	rm -fr ${DEST}

# Truly dynamic version of loader. Rename to {wx}ebshell if you dare.

"${DEST}/poc" : poc.c
	${CC} ${CCOPTS} -o "${DEST}/poc" poc.c -ldl

APPDIR := EekBoek.app

# http://www.mactipsandtricks.com/website/articles/Wiley_HT_appBundles2.lasso

app : ppl app1

app1 :
	rm -fr ${APPDIR} || rm -fr ${APPDIR}
	cp -a "${DEST}/" "${APPDIR}/"
	mkdir -p "${APPDIR}/Contents/MacOS"
	mkdir -p "${APPDIR}/Contents/Resources"
	cp PkgInfo Info.plist "${APPDIR}/Contents"
	cp "${DEST}/eb.icns" "${APPDIR}/Contents/Resources"
	cp "${DEST}/eb-doc.icns" "${APPDIR}/Contents/Resources"
	cd "${APPDIR}"; mv ebshell ebwxshell dndhandler Contents/MacOS
	cd "${APPDIR}"; mv script lib Contents/MacOS
	cd "${APPDIR}"; mv lib*.dylib Contents/MacOS
	cd "${APPDIR}"; rm -f MANIFEST META.yml
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libwx*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/lib/auto/Wx/*.bundle
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/lib/auto/Wx/*/*.bundle

dmg : app dmg1

dmg1 :
	rm -f EekBoek-Installer.dmg
	bash ./create-dmg \
		--volname "EekBoek 2.04" \
		--volicon "${APPDIR}/eb.icns" \
		--window-pos 200 200 \
		--window-size 600 300 \
		--icon "${APPDIR}" 50 50 \
		--add-file "READ ME FIRST.html" README.html 300 50 \
		--hide-extension "READ ME FIRST.html" \
		EekBoek-Installer.dmg "${APPDIR}"

clean ::
	rm -fr ${APPDIR}

mount ::
	open EekBoek-Installer.dmg

umount ::
	hdiutil detach "/Volumes/EekBoek 2.04"
