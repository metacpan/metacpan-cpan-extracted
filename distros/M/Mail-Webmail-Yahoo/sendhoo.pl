#!/usr/bin/perl -w

#  Simon Drabble	03/22/02
#  sdrabble@cpan.org
#  $Id: sendhoo.pl,v 1.6 2003/10/09 21:46:14 simon Exp $
#


use strict;

my $name = $ARGV[0] or &usage, die;
my $pass = $ARGV[1] or &usage, die;
my $to   = $ARGV[2] or &usage, die; 
my $subj = $ARGV[3] or &usage, die; 
my $body = $ARGV[4] or &usage, die; 

exec("yahootils.pl --user=$name --pass=$pass --send --to=$to --subject=$subj --message=$body");


sub usage
{
	warn "This script has been superceded by yahootils.pl";
	print qq{
$0 <yahoo username> <yahoo password> <to-list> <subject> <body>
  to-list is a comma-separated lists of addresses.
};	
}
