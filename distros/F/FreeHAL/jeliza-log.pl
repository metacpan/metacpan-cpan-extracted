#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify  
#   it under the terms of the GNU General Public License as published by  
#   the Free Software Foundation; either version 3 of the License, or     
#   (at your option) any later version.                                   
#                                                                         

$| = 1;

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use AI::FreeHAL::Config;

our $cgi = new CGI;
print $cgi->header();

our $dir = './';


sub footer {
	open my $template, "<", "footer.template.html";
	print join '', <$template>;
	close $template;
}


open my $template, "<", "header.template.html";
print join '', <$template>;
close $template;


open my $dialog_file, "<", "dialog.txt";
my @dialog_lines 
  = grep { /\t.*?\t/ }
    <$dialog_file>;
    
foreach ( @dialog_lines ) {
	s/[;]+[-]*[)]+/<img src="wink.png" \/>/igm;
	s/[:]+[-]*[)]+/<img src="grin.png" \/>/igm;
}
    
my %ip_to_dialog = ();

foreach my $line (@dialog_lines) {
	chomp $line;
	$line =~ s/[:]+/:/igm;
	my ($datum, $ip, $talk) = split /\t/, $line;
	
	$datum =~ s/.*?\s+//i; # no 'g', only once!
	
	$talk =~ s/Mensch[:]/Mensch: /igm;
	
	if ( !$ip_to_dialog{ $ip } ) {
		$ip_to_dialog{ $ip } = [];
	}
	
	push @{ $ip_to_dialog{ $ip } }, $datum . "\t" . $talk;
}

print << "EOT";
<p>
<a href="jeliza-log.pl">Auswahl: Datum</a>
</p>

EOT

my %dates_ip = ();
foreach my $ip (keys %ip_to_dialog) {
	my $date = (split /\t/, (@{ $ip_to_dialog{ $ip } }[0]))[0];
	$dates_ip{ $date } = $ip;
}
my @dates_sorted = sort keys %dates_ip;

foreach my $date (@dates_sorted) {
	my $ip = $dates_ip{ $date };
	
	print "<h2>" . $date . " - " . $ip . "</h2>\n";
	print "<pre>";
	print join '<br />', @{ $ip_to_dialog{ $ip } };
	print "</pre>\n\n";
}

close $dialog_file;



my $statement = << "EOT";
<p style="color: black !important; font-size: 10pt !important; line-height: 28px; margin: 15px !important; background-color: #ffca9b !important; padding: 10px !important; margin-right: 300px !important;">
	Wir bitten um seri&ouml;se Gespr&auml;che mit JEliza; <br />
	JEliza ist ein ernst gemeintes Projekt zur Entwicklung eines Gespr&auml;chssimulators. <br />
	Daher bittet das JEliza Team ausdr&uuml;cklich darum, an Beleidigungen und vulg&auml;ren Ausdr&uuml;cken zu sparen.
</p>
EOT


print footer();
exit(0);


1;
