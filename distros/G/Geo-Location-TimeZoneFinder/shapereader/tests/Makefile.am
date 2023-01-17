DIST_SUBDIRS = data

LDADD = ../libshapereader.a

check_PROGRAMS = test_convert test_dbf test_box test_polygon
check_HEADERS = tap.h
AM_DEFAULT_SOURCE_EXT = .c

AM_TESTS_ENVIRONMENT = \
datadir=$(srcdir)/data; export datadir;

TEST_LOG_DRIVER = env AM_TAP_AWK='$(AWK)' $(SHELL) \
                  $(top_srcdir)/build-aux/tap-driver.sh
TESTS = $(check_PROGRAMS)
