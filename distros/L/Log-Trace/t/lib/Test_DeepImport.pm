#!/usr/local/bin/perl -w
# $Id: Test_DeepImport.pm,v 1.3 2004/11/19 12:53:32 simonf Exp $
package Test_DeepImport;
use vars '$VERSION'; $VERSION = 0.00001;

use strict;

sub new {
    TRACE('Creating object');
    return bless \do {my $x}, shift;
}

sub hello { TRACE('Hello World!') }
sub first { &next }
sub next  { TRACE('IN NEXT') }
sub ether { TRACE('How did we get here?') }

sub TRACE {}
sub DUMP  {}

package Test_DeepImport_Without_TRACE;

sub test {1};

1;
