#!/usr/bin/perl
use strict;

use GSM::SMS::NBS;
use Getopt::Long;

my $msisdn;
my $text;
my $imagefile;
my $transportconfig;

GetOptions( "msisdn=s" 		=> \$msisdn,
			"text=s"		=> \$text,
			"image=s"		=> \$imagefile,
			"config:s"		=> \$transportconfig
		  );

unless ($msisdn && $text && $imagefile ) {
print <<EOT;
Usage: $0 --msisdn=<msisdn> --text=<text> --image=<image> [--config=<transport>] 
EOT
exit(1);
}

my $nbs = GSM::SMS::NBS->new( -config_file => $transportconfig );

print $nbs->sendPictureMessage_file( $msisdn, $text, $imagefile ); 
