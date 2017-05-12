#!/usr/gnu/bin/perl -w
#
# Name:
#	test.pl.
#
# Purpose:
#	To test Getopt::Simple.
#
# Usage:
#	>perl testSimple.pl -q -u User -p Pass -l 333.222.111.000 -ara A -ara B
#
# Tabs:
#	4 spaces || die.
#
# Version:
#	1.00 20-Aug-97
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 1999-2002 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html
# --------------------------------------------------------------------------

use strict;
#no strict 'refs';

use Getopt::Simple qw($switch);

my($option);

# --------------------------------------------------------------------------

sub init
{
	my($default) =
	{
	help =>
		{
		type	=> '',
		env		=> '-',
		default	=> '',
		order	=> 1,
		},
	quiet =>
		{
		type	=> '',
		env		=> '-',
		default	=> '',
		order	=> 2,
		},
	username =>
		{
		type	=> '=s',
		env		=> '$USER',
		default	=> $ENV{'USER'} || 'RonSavage',
		verbose	=> 'Specify the username on the remote machine',
		order	=> 3,
		},
	password =>
		{
		type	=> '=s',
		env		=> '-',
		default	=> 'password',
		verbose	=> 'Specify the password on the remote machine',
		order	=> 4,
		},
	remoteIP =>
		{
		type	=> '=s',
		env		=> '$REMOTEHOST',
		default	=> $ENV{'REMOTEHOST'} || 'UnixBox',
		order	=> 5,
		},
	localIP =>
		{
		type	=> '=s',
		env		=> '$HOST',
		default	=> $ENV{'HOST'} || '127.0.0.1',
		order	=> 6,
		},
	home =>
		{
		type	=> '=s',
		env		=> '$HOME',
		default	=> $ENV{'HOME'} || 'C:',
		verbose	=> 'Specify the home directory on the local machine',
		order	=> 7,
		},
	remoteHome =>
		{
		type	=> '=s',
		env		=> '-',
		default	=> '/users/home/dir',
		verbose	=> 'Specify the home directory on the remote machine',
		order	=> 8,
		},
	ara =>
		{
		type	=> '=s@',
		env		=> '-',
		default	=> [qw/X Y Z/],
		order	=> 9,
		},
	};

	$option = Getopt::Simple -> new();

	if (! $option -> getOptions($default, "Usage: testSimple.pl [options]") )
	{
		exit(-1);	# Failure.
	}

}	# End of init.

# --------------------------------------------------------------------------

&init();

print "Report 1. The current value of each option: \n";
$option -> dumpOptions();

print "Report 2. The current value of some options: \n";
print "username:      $option->{'switch'}{'username'}. \n";
print "password:      $option->{'switch'}{'password'}. \n";
print "remoteIP:      $$switch{'remoteIP'}. \n";
print "localIP:       $$switch{'localIP'}.  \n";
print "ara[0]:        $$switch{'ara'}[0]. \n" if ($$switch{'ara'}[0]);
# Test long $switch -> {'switchName'} rather than short $$switch{'switchName'}.
# Use '->' inside double quotes, but safely use ' -> ' outside...
print "ara[1]:        $switch->{'ara'}[1]. \n" if ($switch -> {'ara'}[1]);
print "ara[2]:        $switch->{'ara'}[2]. \n" if ($switch -> {'ara'}[2]);
print "\n";

print "Report 3. The help text: \n";
$option -> helpOptions();

# Success.
exit(0);
