#!/usr/local/bin/perl -w
# $Id: Test_DelayedImport.pm,v 1.2 2004/11/19 12:53:32 simonf Exp $
package Test_DelayedImport;
use vars '$VERSION'; $VERSION = 0.00001;

use strict;

sub hello { TRACE('Hello World!') }

sub TRACE {}

1;
