package HTTP::WebTest::Plugin::Cookies;
use strict;
# Dummy package Cookies
# 
# Purpose: to overrule the original Cookies package,
# as this one insists on testing for the 'port'
# property which is missing with file:// URI's
#
# $Id: Cookies.pm,v 1.1.1.1 2002/10/30 21:25:49 joezespak Exp $
#
use base qw(HTTP::WebTest::Plugin);

sub cookie { }
sub cookies { }
sub send_cookies { }
sub accept_cookies { }

1;

