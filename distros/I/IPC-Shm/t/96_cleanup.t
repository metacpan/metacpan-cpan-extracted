#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 3;

use IPC::Shm;

# MAKE A FEW VARIABLES

our $pkgvar : Shm = { foo => { bar => 'bam' } };

# DETACH FROM THOSE VARIABLES

ok( untie $pkgvar,			"untie \$pkgvar" );
undef $pkgvar;
ok( 1,					"undef \$pkgvar" );

# GLOBAL CLEANUP

ok( IPC::Shm->cleanup,			"IPC::Shm->cleanup" );

