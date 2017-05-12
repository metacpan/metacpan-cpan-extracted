#! /usr/bin/perl
# $Id: store_att.pl,v 1.3 2001/09/07 11:06:15 parkerpine Exp $

use strict;
use lib "../../";
use Mail::MboxParser;

my @Mboxes;
my $Dir = shift;
if (-d $Dir) {
	opendir DIR, $Dir or die "Error: Could not open $Dir: $!";
	@Mboxes = readdir DIR ;
}
else {
	push @Mboxes, $Dir;
}

my $Mb = Mail::MboxParser->new($Mboxes[0]);

for my $m (@Mboxes) {
	my $mbox;
	if (-e $m) 	{ $mbox = $m }
	else 		{ $mbox = "$Dir/$m" }
	$Mb->open($mbox);
	$_->store_all_attachements(path => '/tmp') for ($Mb->get_messages);
}
		
	
