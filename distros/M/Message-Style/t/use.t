#!/usr/bin/env perl
$^W=1; # for systems where env gets confused by "perl -w"
use strict;
use vars qw( $VERSION );

# $Id: use.t,v 1.1 2004/10/22 20:57:30 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Test;
BEGIN { plan tests => 1 }

# Does the module compile?
use Message::Style; ok(1);

exit;
