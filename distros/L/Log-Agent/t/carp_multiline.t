#!./perl
###########################################################################
#
#   carp_multiline.t
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use Test;
use Carp;
use Log::Agent;

BEGIN { plan tests => 1 }

eval { croak "Yo\nla\ntengo" }; $die1 = $@; eval { logcroak "Yo\nla\ntengo" };
$die2 = $@;
$die1 =~ s/^\s+eval.*\n//m;
$die1 =~ s/(at .* line \d+)\./$1/m; # I'm not gonna bother.

ok($die1 eq $die2);
