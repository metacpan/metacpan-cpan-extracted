#!/usr/bin/perl -w

use IO::Interactive qw(is_interactive);

if( is_interactive() ) 
	{
	print "interactive\n\n";
	}
else 
	{
	print "NOT interactive\n\n";
	}