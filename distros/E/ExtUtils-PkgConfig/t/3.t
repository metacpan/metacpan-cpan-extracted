#
# $Id$
#

use strict;
use warnings;
use English; # uses $OSNAME below

use Test::More tests => 6;
use ExtUtils::PkgConfig;

$ENV{PKG_CONFIG_PATH} = './t/';
my ($major, $minor) = split /\./, `pkg-config --version`;

ok( ExtUtils::PkgConfig->atleast_version(qw/test_glib-2.0/, '2.2.0') );
ok( not ExtUtils::PkgConfig->atleast_version(qw/test_glib-2.0/, '2.3.0') );

ok( ExtUtils::PkgConfig->exact_version(qw/test_glib-2.0/, '2.2.3') );
ok( not ExtUtils::PkgConfig->exact_version(qw/test_glib-2.0/, '2.3.0') );

SKIP: {
    skip("OpenBSD bug in pkg-config clone", 2)
      if($OSNAME eq "openbsd" && ($major == 0 && $minor <= 26));
    ok( ExtUtils::PkgConfig->max_version(qw/test_glib-2.0/, '2.3.0') );
    ok( not ExtUtils::PkgConfig->max_version(qw/test_glib-2.0/, '2.1.0') );
}
