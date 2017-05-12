#!/usr/bin/perl
use strict;

use GSM::SMS::NBS;
use Getopt::Long;

my $msisdn;
my $text;
my $transportconfig;

GetOptions( "msisdn=s" 		=> \$msisdn,
			"text=s"		=> \$text,
			"config:s"		=> \$transportconfig
		  );

unless ($msisdn && $text ) {
print <<EOT;
Usage: $0 --msisdn=<msisdn> --text=<text> [--config=<transport>] 
EOT
exit(1);
}

my $nbs = GSM::SMS::NBS->new( $transportconfig );

print $nbs->sendSMSTextMessage( $msisdn, $text ); 
