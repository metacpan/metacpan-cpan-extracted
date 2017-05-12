#!/usr/bin/env perl
$^W=1; # for systems where env gets confused by "perl -w"
use strict;
use vars qw( $VERSION );

# $Id: use.t,v 1.1 2004/07/15 11:20:12 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Test;
BEGIN { plan tests => 3 }

# Does the module compile?
use Linux::TunTap; ok(1);
# Is this a Linux system?
ok($^O eq 'linux');
# Does this system have a suitable device file?
ok(-e '/dev/net/tun');
exit;
