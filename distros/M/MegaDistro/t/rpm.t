#!/usr/bin/perl -w

# Tests whether or not the system can generate a rpm package

use Test::More;
use File::Path;
use File::Spec::Functions qw(rel2abs);

# first check if the system has rpm[build]
`rpmbuild --help > /dev/null 2>&1`;

# assume that $? is 0 if the command succeeded.
if  ( $? == 0 ) { #if rpm is present
	plan tests => 1;
}
else {
	plan skip_all => 'package system is not rpm';
}

# run the megadistro program with specific options, to generate a rpm package
mkpath rel2abs "t/rootdir";
END { rmtree rel2abs "t/rootdir" }

system( "$^X -Iblib/lib bin/megadistro --clean --force --disttype=rpm --modlist=t/test.list --rootdir=t/rootdir" );

ok( glob("t/rootdir/megadistro-0.02-4.*.rpm"), "build rpm" );
