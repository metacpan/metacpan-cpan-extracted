#!/usr/bin/env perl -w

# Creation date: 2003-03-05 07:42:25
# Authors: Don
# Change log:
# $Id: 00use.t,v 1.1 2003/03/05 15:50:25 don Exp $

use strict;

# main
{
    use strict;
    use Test;
    BEGIN { plan tests => 1 }
    
    use HTML::Menu::Hierarchical; ok(1);

}

exit 0;

###############################################################################
# Subroutines

