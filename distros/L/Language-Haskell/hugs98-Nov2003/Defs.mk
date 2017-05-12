MONTH_YEAR = ${shell date +"%B %Y"}
MON_YEAR = ${shell date +"%b%Y"}
YEAR_MONTH_DAY = ${shell date +"%Y%m%d"}

NAME=hugs98

#
# Set to 0 if a snapshot release.
#
MAJOR_RELEASE=1

# convention: a release uses the MON_YEAR form of version,
# while a snapshot uses the YEAR_MONTH_DAY form.
# this should be sync'd with src/version.c
ifeq "$(MAJOR_RELEASE)" "1"
VERSION=${MON_YEAR}
else
VERSION=${YEAR_MONTH_DAY}
endif

# Release number of RPM.
RELEASE=1

PACKAGE=${NAME}-${VERSION}

# TAG=Dec2001
# HSLIBSTAG=hugs-Dec2001
TAG=Nov2003
HSLIBSTAG=HEAD
LIBRARIESTAG=HEAD

HSLIBSDIRS = concurrent data hssource lang net text util
LIBRARIESDIRS = base haskell98 haskell-src network parsec QuickCheck unix \
	GLUT OpenGL

CVSROOT = ${shell cat CVS/Root}
