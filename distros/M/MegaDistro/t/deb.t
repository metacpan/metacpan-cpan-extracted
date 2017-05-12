#!/usr/bin/perl -w

# Tests whether or not the system can generate a deb package

use Test::More;
use File::Path;
use File::Spec::Functions qw(rel2abs);

# first check if the system has [dpkg-]deb
`dpkg-deb --help > /dev/null 2>&1`;

# assume that $? is 0 if the command succeeded.
if  ( $? == 0 ) { #if deb is present
        plan tests => 1;
}
else {
        plan skip_all => 'package system is not deb';
}

mkpath rel2abs "t/rootdir";
END { rmtree rel2abs "t/rootdir" }

# test the packager's ability to generate a deb
system( "$^X -Iblib/lib bin/megadistro --clean --force --disttype=deb --modlist=t/test.list --rootdir=t/rootdir" );
my $DEB = 't/rootdir' . '/' . 'megadistro_0.02-4.deb';
ok( -e "$DEB", "build deb" );
