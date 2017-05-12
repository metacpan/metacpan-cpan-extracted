#
# $Id$
#

use strict;
use warnings;

#########################

use Test::More tests => 10;
BEGIN { use_ok('ExtUtils::PkgConfig') };

require './t/swallow_stderr.inc';

#########################

my ($major, $minor) = split /\./, `pkg-config --version`;
diag ("Testing against pkg-config $major.$minor");

$ENV{PKG_CONFIG_PATH} = './t/';

my %pkg;

# test 1 for success
eval { %pkg = ExtUtils::PkgConfig->find(qw/test_glib-2.0/); };
ok( not $@ );
ok( $pkg{modversion} and $pkg{cflags} and $pkg{libs} );

# test 1 for failure
swallow_stderr (sub {
	eval { %pkg = ExtUtils::PkgConfig->find(qw/bad1/); };
	ok( $@ );
});

ok( ExtUtils::PkgConfig->exists(qw/test_glib-2.0 /) );

# test 2 for success
eval { %pkg = ExtUtils::PkgConfig->find(qw/bad1 test_glib-2.0/); };
ok( not $@ );
ok( $pkg{modversion} and $pkg{cflags} and $pkg{libs} );

ok( ExtUtils::PkgConfig->exists(qw/bad1 test_glib-2.0/) );

# test 2 for failure
swallow_stderr (sub {
	eval { %pkg = ExtUtils::PkgConfig->find(qw/bad1 bad2/); };
	ok( $@ );
});

ok( !ExtUtils::PkgConfig->exists(qw/bad1 bad2/) );
