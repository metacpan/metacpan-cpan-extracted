#!/usr/bin/perl -w

#  Simon Drabble	03/22/02
#  sdrabble@cpan.org
#  $Id: snagmail.pl,v 1.17 2003/10/09 21:46:14 simon Exp $
#


use strict;


warn "This script has been superceded by yahootils.pl";

my $name = $ARGV[0] || ''; # errors will be caught by yahootils
my $pass = $ARGV[1] || '';

exec("yahootils.pl --user=$name --pass=$pass --get Inbox");
