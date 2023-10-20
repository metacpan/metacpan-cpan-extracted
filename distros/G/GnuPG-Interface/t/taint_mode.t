#!/usr/bin/perl -wT
#
# Ensure we can instatiate in Taint mode. Don't need to
# do any work, as GnuPG::Interface runs the command we're going
# to use to detect the version.

use strict;

use lib './t';
use MyTest;

use GnuPG::Interface;

my $gnupg;

# See that we instantiate an object in Taint mode
TEST
{
    $gnupg = GnuPG::Interface->new( call => '/usr/bin/gpg' );
};

# See that version is set
TEST
{
    defined $gnupg->version;
};
