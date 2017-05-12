# This Makefile is for building RPM distributions.

# Starting with Red Hat 8.0, the build functionality was removed from rpm, so
# one has to use rpmbuild instead. SuSE didn't follow this change, so there is
# no rpmbuild on SuSE and rpm still does the job. I like such changes...
RPMBUILD = rpmbuild

RPMTMP = /tmp/rpm
# probably should be uniqueified
TARTMP = /tmp/mktar

SPECFILE=${NAME}.spec

RPMDEFS = --define "_topdir ${RPMTMP}" \
	  --define "name ${NAME}" \
	  --define "version ${VERSION}" \
	  --define "release ${RELEASE}" \

VERSION_SUBSTS = \
    -e "s/define MAJOR_RELEASE.*/define MAJOR_RELEASE ${MAJOR_RELEASE}/" \
    -e "s/VERSION_STRING MONTH_YEAR/VERSION_STRING \"${MONTH_YEAR}\"/" \
    -e "s/VERSION_STRING YYYYMMDD/VERSION_STRING \"${YEAR_MONTH_DAY}\"/"

RC_STRING = RC1
RC_VERSION_SUBSTS = \
    -e "s/define MAJOR_RELEASE.*/define MAJOR_RELEASE ${MAJOR_RELEASE}/" \
    -e "s/VERSION_STRING MONTH_YEAR/VERSION_STRING \"${MON_YEAR} ${RC_STRING}\"/"

# unless you've just unpacked, `make clean' first
tar: ${PACKAGE}.tar.gz

${PACKAGE}.tar.gz:
	-rm -rf ${TARTMP}
	-mkdir -p ${TARTMP}
	cd ${TARTMP}; cvs -d ${CVSROOT} export -r${TAG} hugs98
	cd ${TARTMP}/hugs98; cvs -d ${CVSROOT} export -r${HSLIBSTAG} $(addprefix fptools/hslibs/,${HSLIBSDIRS})
	cd ${TARTMP}/hugs98; cvs -d ${CVSROOT} export -r${LIBRARIESTAG} $(addprefix fptools/libraries/,${LIBRARIESDIRS})
	# Unused, and the pathnames in there are too long for portable tar
	cd ${TARTMP}/hugs98; rm -rf fptools/libraries/parsec/examples
	# preprocess these, so the package can be built without happy & ghc
	# changes here should be reflected also in Makefile (sorry)
	find ${TARTMP}/hugs98/fptools/libraries -name "*.ly" -o -name "*.y" |\
		xargs -l happy
	find ${TARTMP}/hugs98/fptools/libraries -name "*.hsc" |\
		xargs -l hsc2hs --no-compile
	find ${TARTMP}/hugs98/fptools/libraries -name "*_hsc_make.c" |\
		xargs src/unix/hsc_kludge
	cp ${TARTMP}/hugs98/src/version.c /tmp/mktar
	cd ${TARTMP}/hugs98/src; sed ${VERSION_SUBSTS} < ${TARTMP}/version.c > ${TARTMP}/hugs98/src/version.c
	# using `make parser.c' would be best, but by default yacc
	# will be used, and yacc is, for some reason, incompatible
	cd ${TARTMP}/hugs98/src; bison -y parser.y; mv y.tab.c parser.c
	# Siggy deren't like these in distros
	cd ${TARTMP}/hugs98; rm -rf tests
	cd ${TARTMP}/hugs98/src/unix; autoconf # ; autoheader
	mv ${TARTMP}/hugs98 ${TARTMP}/${PACKAGE}
	cd ${TARTMP}; tar cf /tmp/${NAME}.tar ${PACKAGE}
	gzip -9 /tmp/${NAME}.tar
	mv /tmp/${NAME}.tar.gz ${PACKAGE}.tar.gz

rpm-dirs:
	-mkdir ${RPMTMP}
	-mkdir ${RPMTMP}/BUILD
	-mkdir ${RPMTMP}/RPMS
	-mkdir ${RPMTMP}/RPMS/i386
	-mkdir ${RPMTMP}/SOURCES
	-mkdir ${RPMTMP}/SPECS
	-mkdir ${RPMTMP}/SRPMS

rpm: tar rpm-dirs
	cp ${PACKAGE}.tar.gz ${RPMTMP}/SOURCES
	${RPMBUILD} ${RPMDEFS} -ba ${SPECFILE}
	mv ${RPMTMP}/RPMS/i386/${PACKAGE}-${RELEASE}.i386.rpm .
	mv ${RPMTMP}/SRPMS/${PACKAGE}-${RELEASE}.src.rpm .

rc-rpm:
	${MAKE} VERSION_SUBSTS='${RC_VERSION_SUBSTS}' rpm

clean:
	-cd src; if test -f Makefile; then make veryclean; fi
	-cd docs; if test -f Makefile; then make veryclean; fi
	-rm -f ${PACKAGE}.tar.gz
	-rm -f ${PACKAGE}-*.rpm
