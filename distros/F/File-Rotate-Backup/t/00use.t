#!/usr/bin/perl

# Creation date: 2003-04-06 11:36:54
# Authors: Don
# Change log:
# $Id: 00use.t,v 1.2 2003/04/07 04:20:40 don Exp $

use strict;

# main
{
    use strict;
    use Test;
    BEGIN { plan tests => 1 }
    
    use File::Rotate::Backup; ok(1);

}

exit 0;

###############################################################################
# Subroutines

