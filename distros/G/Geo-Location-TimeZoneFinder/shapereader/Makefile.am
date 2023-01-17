EXTRA_DIST = CONTRIBUTING.md Doxyfile Makefile.PL shapereader.bib

SUBDIRS = tests

pkgconfig_DATA = shapereader.pc

lib_LIBRARIES = libshapereader.a
pkginclude_HEADERS = dbf.h shp-box.h shp-point.h shp-polygon.h shp.h shapereader.h
noinst_HEADERS = convert.h
libshapereader_a_SOURCES = convert.c dbf.c shp-box.c shp-polygon.c shp.c
