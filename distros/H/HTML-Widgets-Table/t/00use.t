#!/usr/bin/perl

# Creation date: 2003-09-07 22:49:49
# Authors: Don
# Change log:
# $Id: 00use.t,v 1.1 2003/09/08 14:05:05 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };

    use Test;
    BEGIN { plan tests => 1 }
    
    use HTML::Widgets::Table; ok(1);

}

exit 0;

###############################################################################
# Subroutines

