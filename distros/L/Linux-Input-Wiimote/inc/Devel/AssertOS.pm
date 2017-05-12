#line 1
# $Id: AssertOS.pm,v 1.4 2007/10/19 16:59:04 drhyde Exp $

package Devel::AssertOS;

use Devel::CheckOS;

use strict;

use vars qw($VERSION);

$VERSION = '1.1';

# localising prevents the warningness leaking out of this module
local $^W = 1;    # use warnings is a 5.6-ism

#line 31

sub import {
    shift;
    die("Devel::AssertOS needs at least one parameter\n") unless(@_);
    Devel::CheckOS::die_if_os_isnt(@_);
}

#line 81

$^O;
