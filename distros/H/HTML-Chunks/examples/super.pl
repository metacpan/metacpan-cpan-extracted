#!/usr/bin/perl

# $Id: super.pl,v 1.1 2005/06/28 07:05:32 mark Exp $
#
# A very simple example of using conditionals via HTML::Chunks::Super
#
# The chunk "file" is at the end of this script

use HTML::Chunks::Super;
use strict;

unless (@ARGV)
{
	die qq|Usage: super.pl "your name"\n|;
}

# create a new engine and read our chunk definitions
my $engine = new HTML::Chunks::Super(\*DATA);

# output the page, sending our script arg as the 'name'
$engine->output('super_page', { name => $ARGV[0] });

__END__

<!-- BEGIN super_page -->
Hello ##name##!

<!-- IF length(##name##) <= 3 -->
That's a rather short name!  Try a longer one.
<!-- ELSIF ##name## =~ /[A-Z]/ && ##name## !~ /[a-z]/ -->
You don't have to yell!
<!-- ELSE -->
Nice to meet you.  Now try a short name (3-characters or less)
or one in all CAPS.
<!-- ENDIF -->

<!-- END super_page -->
